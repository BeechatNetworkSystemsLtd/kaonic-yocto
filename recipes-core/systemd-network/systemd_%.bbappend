FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " file://hostapd.network"

do_install:append () {
    install -d ${D}${systemd_unitdir}/network
    install -m 0644 ${WORKDIR}/hostapd.network ${D}${systemd_unitdir}/network/
}

FILES_${PN} += "${systemd_unitdir}/network/hostapd.network"

