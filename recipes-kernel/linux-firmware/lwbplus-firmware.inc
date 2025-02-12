
LWB_RELEASE_URI = "https://github.com/Ezurio/Sterling-LWB-and-LWB5-Release-Packages/releases/download"

SRC_URI:append:stm32mp1common = " ${LWB_RELEASE_URI}/LRD-REL-12.103.0.5/summit-lwbplus-firmware-12.103.0.5.tar.bz2;name=lwbplus-firmware"
SRC_URI[lwbplus-firmware.sha256sum] = "1ceea040ba1f0ff77e3ec48dac2f6b5e289c8ae602a452fce9575172ef3e3f7d"

LWBPLUS_FW_DIR = "${WORKDIR}/lib/firmware/brcm/"

