
FILESEXTRAPATHS:prepend:stm32mpcommon := "${THISDIR}/${PN}:"

# Add calibration file
SRC_URI:append:stm32mpcommon = " git://github.com/murata-wireless/cyw-fmac-nvram.git;protocol=https;nobranch=1;name=nvram;destsuffix=nvram-murata-master "
SRCREV_nvram = "e5789896af74c5e657bf329eae711ef5a034b662"
SRC_URI:append:stm32mpcommon = " git://github.com/murata-wireless/cyw-fmac-fw.git;protocol=https;nobranch=1;name=murata;destsuffix=murata-master "
SRCREV_murata = "c85ec7bb4e8a8a113d458d2869dd0ef7b3136069"
SRCREV_FORMAT = "linux-firmware-murata"

do_install:append:stm32mpcommon() {

   # Install calibration file
   install -m 0644 ${WORKDIR}/nvram-murata-master/cyfmac43439-sdio.1YN.txt ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt

   # disable Wakeup on WLAN
   sed -i "s/muxenab=\(.*\)$/#muxenab=\1/g" ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt

   # Change crystal frequency to 26MHz
   sed -i 's/xtalfreq=[0-9]\+/xtalfreq=26000/g' ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt

   # Install calibration file
   install -m 0644 ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.txt ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx.txt

   # Take newest murata firmware
   install -m 0644 ${WORKDIR}/murata-master/cyfmac43439-sdio.bin ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.bin
   install -m 0644 ${WORKDIR}/murata-master/cyfmac43439-sdio.1YN.clm_blob ${D}${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.clm_blob

   # Add symlinks for newest kernel compatibility
   cd ${D}${nonarch_base_libdir}/firmware/brcm/
   ln -sf brcmfmac43439-sdio.bin brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx.bin
}

FILES:${PN}-bcm43439:append:stm32mpcommon = " \
    ${nonarch_base_libdir}/firmware/brcm/brcmfmac43439-sdio.st,stm32mp151a-kaonic-mx* \
 "
