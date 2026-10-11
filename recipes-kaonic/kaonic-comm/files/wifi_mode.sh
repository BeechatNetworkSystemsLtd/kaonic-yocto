#!/bin/sh
# Source of truth: kaonic-gateway/kaonic-gateway/system/wifi_mode.sh (the gateway refreshes this file at start)

set -eu

MODE_FILE="/etc/kaonic/wifi-mode"
ANTENNA_FILE="/etc/kaonic/wifi-antenna"
MACHINE_FILE="/etc/kaonic/kaonic_machine"
WPA_CONF="/etc/wpa_supplicant-wlan0.conf"
WLAN_OVERRIDE="/etc/systemd/network/62-wlan0.network"
WPA_PID_FILE="/run/wpa_supplicant-wlan0.pid"
WLAN_IFACE="wlan0"
ANTENNA_GPIOCHIP="8"
ANTENNA_GPIOLINE="0"

# USB uplink: the phone on the USB port shares its internet (Android
# "Ethernet tethering") and this node takes an address and a default route
# from it. usb0 then leaves the bridge, so the phone's DHCP server never
# reaches the node's own Wi-Fi and USB clients.
USB_UPLINK_FILE="/etc/kaonic/usb-uplink"
USB0_OVERRIDE="/etc/systemd/network/61-usb0.network"
USB_IFACE="usb0"
# Not 192.168.10.0/24: that stays on br0 for the Wi-Fi and USB clients.
USB_UPLINK_FALLBACK_ADDR="192.168.11.1/24"
# The node's own DHCP server on br0 (192.168.10.0/24). Off when something
# else on that network is meant to hand out addresses.
DHCP_SERVER_FILE="/etc/kaonic/dhcp-server"
BR0_DHCP_DROPIN="/etc/systemd/network/60-br0.network.d/kaonic-dhcp.conf"
# Push routes: DHCP moves from systemd-networkd to dnsmasq, which can hand
# clients classless static routes (option 121) for the other Kaonics'
# networks. The gateway keeps the route list in DHCP_OPTS_FILE current.
PUSH_ROUTES_FILE="/etc/kaonic/push-routes"
DNSMASQ_DHCP_CONF="/etc/dnsmasq.d/kaonic-dhcp.conf"
DNSMASQ_BASE_CONF="/etc/dnsmasq.d/hostapd-dns.conf"
DHCP_OPTS_FILE="/run/kaonic-dhcp-opts"
BR0_ADDR="192.168.10.1"
# Short lease: a phone learns within minutes that a route appeared or went.
BR0_RANGE="192.168.10.10,192.168.10.109,10m"

usage() {
    echo "Usage: $0 ap | sta <ssid> <passphrase> | antenna <internal|external> | usb-uplink <on|off> | dhcp-server <on|off> | push-routes <on|off> | apply | status" >&2
    exit 1
}

current_usb_uplink() {
    if [ -f "$USB_UPLINK_FILE" ]; then sed -n '1p' "$USB_UPLINK_FILE"; else echo "off"; fi
}

current_dhcp_server() {
    if [ -f "$DHCP_SERVER_FILE" ]; then sed -n '1p' "$DHCP_SERVER_FILE"; else echo "on"; fi
}

current_push_routes() {
    if [ -f "$PUSH_ROUTES_FILE" ]; then sed -n '1p' "$PUSH_ROUTES_FILE"; else echo "off"; fi
}

# dnsmasq serves DHCP on br0 (networkd's server off) only while routes are
# pushed and the DHCP server is on; otherwise its DHCP stays disabled as the
# image ships it.
apply_dnsmasq_dhcp() {
    if [ "$(current_dhcp_server)" = "on" ] && [ "$(current_push_routes)" = "on" ]; then
        install -d /etc/dnsmasq.d
        [ -s "$DHCP_OPTS_FILE" ] || printf 'option:router\noption:dns-server\n' > "$DHCP_OPTS_FILE"
        [ -f "$DNSMASQ_BASE_CONF" ] && sed -i 's/^no-dhcp-interface=br0/#no-dhcp-interface=br0 (dhcp by kaonic-dhcp.conf)/' "$DNSMASQ_BASE_CONF"
        cat > "$DNSMASQ_DHCP_CONF" <<EOF
# Written by kaonic-wifi-mode: DHCP for br0 served here so clients also get
# routes to the other Kaonics' networks (option 121, from $DHCP_OPTS_FILE).
dhcp-range=$BR0_RANGE
# No router/DNS here: the gateway adds them to the optsfile only while this
# node can forward somewhere, so a laptop with its own Wi-Fi keeps it.
dhcp-optsfile=$DHCP_OPTS_FILE
dhcp-authoritative
EOF
    else
        rm -f "$DNSMASQ_DHCP_CONF"
        [ -f "$DNSMASQ_BASE_CONF" ] && sed -i 's/^#no-dhcp-interface=br0 (dhcp by kaonic-dhcp.conf)/no-dhcp-interface=br0/' "$DNSMASQ_BASE_CONF"
    fi
    systemctl restart dnsmasq.service 2>/dev/null || true
}

apply_usb_uplink() {
    case "$(current_usb_uplink)" in
        on)
            install -d /etc/systemd/network
            cat > "$USB0_OVERRIDE" <<EOF
[Match]
Name=$USB_IFACE
Type=gadget

[Network]
# Written by kaonic-wifi-mode: USB uplink. The phone tethers to us, so usb0
# is a client here, not a bridge port.
DHCP=ipv4
IPv6AcceptRA=no
# A fixed fallback address as well, so the node can always be reached over
# USB at $USB_UPLINK_FALLBACK_ADDR even when nothing on the other end serves DHCP.
Address=$USB_UPLINK_FALLBACK_ADDR
# Link-local stays on: with no DHCP server on the other end the node is
# still reachable as <codename>.local over the USB link, so switching this
# on can never lock the operator out.
LinkLocalAddressing=yes

[DHCPv4]
# Beats the Wi-Fi station's default route (1024) whenever the phone offers one.
RouteMetric=512
UseDNS=yes
EOF
            ip link set "$USB_IFACE" nomaster 2>/dev/null || true
            ;;
        *)
            rm -f "$USB0_OVERRIDE"
            ;;
    esac
    networkctl reload 2>/dev/null || true
    networkctl reconfigure "$USB_IFACE" 2>/dev/null || true
}

apply_dhcp_server() {
    apply_dnsmasq_dhcp
    case "$(current_dhcp_server):$(current_push_routes)" in
        on:off)
            rm -f "$BR0_DHCP_DROPIN"
            ;;
        *)
            install -d "$(dirname "$BR0_DHCP_DROPIN")"
            cat > "$BR0_DHCP_DROPIN" <<EOF
[Network]
# Written by kaonic-wifi-mode: networkd's DHCP server is off (the node's
# DHCP is either switched off, or served by dnsmasq to push routes).
DHCPServer=no
EOF
            ;;
    esac
    networkctl reload 2>/dev/null || true
    networkctl reconfigure br0 2>/dev/null || true
}

wifi_iface_present() {
    ip link show "$WLAN_IFACE" >/dev/null 2>&1
}

write_mode() {
    install -d /etc/kaonic
    printf '%s\n' "$1" > "$MODE_FILE"
}

write_sta_network_override() {
    install -d /etc/systemd/network
    cat > "$WLAN_OVERRIDE" <<'EOF'
[Match]
Name=wlan0

[Network]
DHCP=yes
IPv6AcceptRA=yes
EOF
}

stop_wpa_supplicant() {
    if [ -f "$WPA_PID_FILE" ]; then
        pid="$(cat "$WPA_PID_FILE")"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
        fi
        rm -f "$WPA_PID_FILE"
    fi
}

start_wpa_supplicant() {
    if [ ! -f "$WPA_CONF" ]; then
        echo "Missing WPA config: $WPA_CONF" >&2
        exit 1
    fi

    if ! wifi_iface_present; then
        echo "WiFi interface $WLAN_IFACE is not present yet; skipping STA bring-up"
        return 0
    fi

    stop_wpa_supplicant

    ip link set "$WLAN_IFACE" down || true
    ip link set "$WLAN_IFACE" nomaster || true
    ip link set "$WLAN_IFACE" up

    wpa_supplicant -B -P "$WPA_PID_FILE" -i "$WLAN_IFACE" -c "$WPA_CONF"
    networkctl reload
    networkctl reconfigure "$WLAN_IFACE" || true
}

render_wpa_config() {
    ssid="$1"
    passphrase="$2"

    {
        printf 'ctrl_interface=/run/wpa_supplicant\n'
        printf 'update_config=1\n\n'
        wpa_passphrase "$ssid" "$passphrase"
    } > "$WPA_CONF"

    chmod 600 "$WPA_CONF"
}

apply_ap_mode() {
    if ! wifi_iface_present; then
        echo "WiFi interface $WLAN_IFACE is not present yet; skipping AP bring-up"
        return 0
    fi

    stop_wpa_supplicant
    rm -f "$WLAN_OVERRIDE"
    ip link set "$WLAN_IFACE" down || true
    ip link set "$WLAN_IFACE" nomaster || true
    systemctl restart systemd-networkd.service
    systemctl start hostapd.service
}

apply_sta_mode() {
    if ! wifi_iface_present; then
        echo "WiFi interface $WLAN_IFACE is not present yet; skipping STA mode"
        return 0
    fi

    systemctl stop hostapd.service || true
    write_sta_network_override
    systemctl restart systemd-networkd.service
    start_wpa_supplicant
}

current_mode() {
    if [ -f "$MODE_FILE" ]; then
        sed -n '1p' "$MODE_FILE"
    else
        echo "ap"
    fi
}

write_antenna() {
    install -d /etc/kaonic
    printf '%s\n' "$1" > "$ANTENNA_FILE"
}

current_antenna() {
    if [ -f "$ANTENNA_FILE" ]; then
        sed -n '1p' "$ANTENNA_FILE"
    else
        echo "internal"
    fi
}

machine_supports_antenna() {
    [ -f "$MACHINE_FILE" ] || return 1
    case "$(sed -n '1p' "$MACHINE_FILE")" in
        stm32mp1-kaonic-protob|stm32mp1-kaonic-protoc) return 0 ;;
        *) return 1 ;;
    esac
}

apply_antenna() {
    if ! machine_supports_antenna; then
        return 0
    fi

    case "$(current_antenna)" in
        internal) value=0 ;;
        external) value=1 ;;
        *) echo "Unknown antenna setting in $ANTENNA_FILE" >&2; return 1 ;;
    esac

    if ! gpioset -z -c "$ANTENNA_GPIOCHIP" "${ANTENNA_GPIOLINE}=${value}" 2>/dev/null; then
        echo "antenna GPIO is already consumed"
    fi
}

show_status() {
    echo "mode: $(current_mode)"
    echo "antenna: $(current_antenna)"
    echo "usb-uplink: $(current_usb_uplink)$( ip -4 addr show dev "$USB_IFACE" 2>/dev/null | awk '/inet / { printf " (%s)", $2 }' )"
    echo "dhcp-server: $(current_dhcp_server)"
    echo "push-routes: $(current_push_routes)$( [ -s "$DHCP_OPTS_FILE" ] && printf ' (%s)' "$(head -1 "$DHCP_OPTS_FILE")" )"
    echo "default-route: $(ip -4 route show default 2>/dev/null | head -1)"
    echo "hostapd: $(systemctl is-active hostapd.service 2>/dev/null || true)"

    if [ -f "$WPA_PID_FILE" ]; then
        echo "wpa_supplicant: running"
    else
        echo "wpa_supplicant: stopped"
    fi

    if wifi_iface_present; then
        iw "$WLAN_IFACE" link || true
    else
        echo "$WLAN_IFACE: absent"
    fi
}

cmd="${1:-}"

case "$cmd" in
    ap)
        [ "$#" -eq 1 ] || usage
        write_mode ap
        apply_ap_mode
        ;;
    sta)
        [ "$#" -eq 3 ] || usage
        render_wpa_config "$2" "$3"
        write_mode sta
        apply_sta_mode
        ;;
    antenna)
        [ "$#" -eq 2 ] || usage
        case "$2" in
            internal|external) ;;
            *) usage ;;
        esac
        write_antenna "$2"
        apply_antenna
        ;;
    usb-uplink)
        [ "$#" -eq 2 ] || usage
        case "$2" in on|off) ;; *) usage ;; esac
        install -d /etc/kaonic
        printf '%s\n' "$2" > "$USB_UPLINK_FILE"
        apply_usb_uplink
        ;;
    dhcp-server)
        [ "$#" -eq 2 ] || usage
        case "$2" in on|off) ;; *) usage ;; esac
        install -d /etc/kaonic
        printf '%s\n' "$2" > "$DHCP_SERVER_FILE"
        apply_dhcp_server
        ;;
    push-routes)
        [ "$#" -eq 2 ] || usage
        case "$2" in on|off) ;; *) usage ;; esac
        install -d /etc/kaonic
        printf '%s\n' "$2" > "$PUSH_ROUTES_FILE"
        apply_dhcp_server
        ;;
    apply)
        [ "$#" -eq 1 ] || usage
        case "$(current_mode)" in
            ap) apply_ap_mode ;;
            sta) apply_sta_mode ;;
            *) echo "Unknown WiFi mode in $MODE_FILE" >&2; exit 1 ;;
        esac
        apply_antenna
        apply_usb_uplink
        apply_dhcp_server
        ;;
    status)
        [ "$#" -eq 1 ] || usage
        show_status
        ;;
    *)
        usage
        ;;
esac
