

do_install:append() {
    rm -f ${D}${systemd_unitdir}/network/53-usb-otg.network
}
