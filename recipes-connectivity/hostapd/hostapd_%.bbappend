FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://hostapd.service"

do_install:append () {
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/hostapd.service ${D}${systemd_system_unitdir}
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "hostapd.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES_${PN} += "${systemd_system_unitdir}/hostapd.service"

