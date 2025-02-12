
include lwbplus-firmware.inc

do_install:append:stm32mpcommon() {
    install -d ${D}${nonarch_base_libdir}/firmware/brcm/

    install -m 644 ${S}/LICENCE.cypress ${D}${nonarch_base_libdir}/firmware/LICENCE.cypress_bcm4343

    install -m 644 ${LWBPLUS_FW_DIR}/BCM4343A2_v001.003.016.0048.0000.hcd ${D}${nonarch_base_libdir}/firmware/brcm/BCM4343A2.hcd

    cd ${D}${nonarch_base_libdir}/firmware/brcm/
    ln -sf BCM4343A2.hcd BCM.st,stm32mp151a-kaonic-mx.hcd
}

FILES:${PN}:append:stm32mpcommon = " \
    ${nonarch_base_libdir}/firmware/brcm/BCM4343A2.hcd \
    ${nonarch_base_libdir}/firmware/brcm/BCM.st,stm32mp151a-kaonic-mx.hcd \
"


