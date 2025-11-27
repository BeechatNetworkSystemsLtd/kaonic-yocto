FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " file://wlan0.network file://usb0.network file://br0.netdev file://br0.network"

do_install:append () {
    install -d ${D}${systemd_unitdir}/network

    install -m 0644 ${WORKDIR}/wlan0.network ${D}${systemd_unitdir}/network/62-wlan0.network
    install -m 0644 ${WORKDIR}/usb0.network ${D}${systemd_unitdir}/network/61-usb0.network
    install -m 0644 ${WORKDIR}/br0.network ${D}${systemd_unitdir}/network/60-br0.network
    install -m 0644 ${WORKDIR}/br0.netdev ${D}${systemd_unitdir}/network/
}

FILES_${PN} += "${systemd_unitdir}/network/62-wlan0.network"
FILES_${PN} += "${systemd_unitdir}/network/61-usb0.network"
FILES_${PN} += "${systemd_unitdir}/network/60-br0.network"
FILES_${PN} += "${systemd_unitdir}/network/br0.netdev"

