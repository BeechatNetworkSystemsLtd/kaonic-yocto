
include lwbplus-firmware.inc

do_install:append:stm32mpcommon() {

   # Remove previous firmware
   rm -f ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt
   rm -f ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.bin
   rm -f ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.clm_blob

   # Install calibration file
   install -m 0644 ${LWBPLUS_FW_DIR}/brcmfmac43439-sdio.txt ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt
   install -m 0644 ${LWBPLUS_FW_DIR}/brcmfmac43439-sdio.bin ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.bin
   install -m 0644 ${LWBPLUS_FW_DIR}/brcmfmac43439-sdio.clm_blob ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.clm_blob

   # # disable Wakeup on WLAN
   # sed -i "s/muxenab=\(.*\)$/#muxenab=\1/g" ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt
   #
   # # Change crystal frequency to 26MHz
   # sed -i 's/xtalfreq=[0-9]\+/xtalfreq=26000/g' ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt

   # # Install calibration file
   # install -m 0644 ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx.txt
   #
   # # Take newest murata firmware
   # install -m 0644 ${WORKDIR}/murata-master/cyfmac43439-sdio.bin ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.bin
   # install -m 0644 ${WORKDIR}/murata-master/cyfmac43439-sdio.1YN.clm_blob ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.clm_blob

   # Add symlinks for newest kernel compatibility
   cd ${D}${nonarch_base_libdir}/firmware/brcm/
   ln -sf brcmfmac43439-sdio.bin brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx.bin
   ln -sf brcmfmac43439-sdio.txt brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx.txt
}

FILES:${PN}-bcm43439:append:stm32mpcommon = " \
    ${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.* \
    ${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx* \
 "
