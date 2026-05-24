FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://hostapd.service"

do_install:append () {
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/hostapd.service ${D}${systemd_system_unitdir}

    if ! grep -qx 'ssid=test' ${D}${sysconfdir}/hostapd.conf; then
        bbfatal "Expected default ssid=test in ${sysconfdir}/hostapd.conf"
    fi
    sed -i 's/^ssid=test$/ssid=Kaonic-1S/' ${D}${sysconfdir}/hostapd.conf
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "hostapd.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += "${systemd_system_unitdir}/hostapd.service"
