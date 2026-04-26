#!/bin/sh

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

usage() {
    echo "Usage: $0 ap | sta <ssid> <passphrase> | antenna <internal|external> | apply | status" >&2
    exit 1
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
    stop_wpa_supplicant
    rm -f "$WLAN_OVERRIDE"
    ip link set "$WLAN_IFACE" down || true
    ip link set "$WLAN_IFACE" nomaster || true
    systemctl restart systemd-networkd.service
    systemctl start hostapd.service
}

apply_sta_mode() {
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
    echo "hostapd: $(systemctl is-active hostapd.service 2>/dev/null || true)"

    if [ -f "$WPA_PID_FILE" ]; then
        echo "wpa_supplicant: running"
    else
        echo "wpa_supplicant: stopped"
    fi

    iw "$WLAN_IFACE" link || true
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
    apply)
        [ "$#" -eq 1 ] || usage
        case "$(current_mode)" in
            ap) apply_ap_mode ;;
            sta) apply_sta_mode ;;
            *) echo "Unknown WiFi mode in $MODE_FILE" >&2; exit 1 ;;
        esac
        apply_antenna
        ;;
    status)
        [ "$#" -eq 1 ] || usage
        show_status
        ;;
    *)
        usage
        ;;
esac
