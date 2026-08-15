FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://hostapd.service"

do_install:append () {
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/hostapd.service ${D}${systemd_system_unitdir}

    # hostapd owns wlan0's bridge membership, not systemd-networkd.
    #
    # networkd can enslave wlan0 from a .network file, but hostapd switches the
    # interface into AP mode *after* that and the type change drops the
    # membership — leaving a board with a configured bridge, a running DHCP
    # server, and wlan0 sitting outside it, so clients associate and never get a
    # lease. Adding the port here happens after the mode switch, so it sticks,
    # and hostapd removes it again when the service stops. That is also what the
    # AP/STA switch needs: in station mode hostapd is not running, so wlan0 is
    # free to take an address from upstream (see wifi_mode.sh).
    conf="${D}${sysconfdir}/hostapd.conf"
    if [ ! -f "$conf" ]; then
        bbfatal "expected hostapd.conf at $conf; the bridge setting has nowhere to go"
    fi
    sed -i '/^[[:space:]]*bridge=/d' "$conf"
    echo "bridge=br0" >> "$conf"
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "hostapd.service"

SYSTEMD_AUTO_ENABLE:${PN} = "disable"

FILES_${PN} += "${systemd_system_unitdir}/hostapd.service"
