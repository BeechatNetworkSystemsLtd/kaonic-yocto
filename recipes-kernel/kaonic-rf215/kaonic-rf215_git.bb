SUMMARY = "Kaonic AT86RF215 radio driver"
DESCRIPTION = "Out-of-tree kernel module for the AT86RF215 transceivers on Kaonic boards"

SECTION = "kernel/modules"
# The core library in lib/ is MIT; the Linux port that wraps it as a module is GPL-2.0.
LICENSE = "MIT & GPL-2.0-only"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=10e710d286f8b11cb655aa05472a6463 \
    file://port/linux-kernel/Kbuild;beginline=1;endline=1;md5=daad6f7f7a0a286391cd7773ccf79340 \
"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit module

PV = "0.1.0+git${SRCPV}"
SRC_URI = "git://github.com/BeechatNetworkSystemsLtd/kaonic-rf215.git;protocol=https;branch=main"
SRCREV = "b8a1d968b3ea2d01955371bc7d7c8ccf7c24a7c8"

SRC_URI += " \
    file://70-kaonic-rf215.rules.in \
    file://kaonic-rf215-update \
"

S = "${WORKDIR}/git"

# The module lives in a subdirectory of the repository, and its own Makefile
# can only build it. So Kbuild is called directly instead: that also gives us
# modules_install, and builds against the exact kernel the image ships.
EXTRA_OEMAKE += "-C ${STAGING_KERNEL_DIR} M=${S}/port/linux-kernel"
MODULES_MODULE_SYMVERS_LOCATION = "port/linux-kernel"

# The SPI device each radio is on. Its interface names (rf09_a, rf24_a,
# rf09_b, rf24_b) are based on it. Radio A is the chip wired to RSTN_A/IRQ_A.
KAONIC_RF215_SPI_A ?= ""
KAONIC_RF215_SPI_B ?= ""
KAONIC_RF215_SPI_A:stm32mp1-kaonic1s-r24 = "spi6.0"
KAONIC_RF215_SPI_B:stm32mp1-kaonic1s-r24 = "spi3.0"
KAONIC_RF215_SPI_A:stm32mp1-kaonic1s-r30 = "spi4.0"
KAONIC_RF215_SPI_B:stm32mp1-kaonic1s-r30 = "spi3.0"
# Kaonic 1X r09 has the same radio wiring as r30.
KAONIC_RF215_SPI_A:stm32mp1-kaonic1x-r09 = "spi4.0"
KAONIC_RF215_SPI_B:stm32mp1-kaonic1x-r09 = "spi3.0"

# mac802154 comes in through the module's own dependencies; kmod provides the
# tools the update helper runs.
RDEPENDS:${PN} += "kmod"

FILES:${PN} += " \
    ${nonarch_base_libdir}/udev/rules.d/70-kaonic-rf215.rules \
    ${sbindir}/kaonic-rf215-update \
"

do_install:append() {
    if [ -z "${KAONIC_RF215_SPI_A}" ] || [ -z "${KAONIC_RF215_SPI_B}" ]; then
        bbfatal "KAONIC_RF215_SPI_A/B are not set for ${MACHINE}"
    fi

    install -d ${D}${nonarch_base_libdir}/udev/rules.d
    sed -e 's/@SPI_A@/${KAONIC_RF215_SPI_A}/g' \
        -e 's/@SPI_B@/${KAONIC_RF215_SPI_B}/g' \
        ${WORKDIR}/70-kaonic-rf215.rules.in \
        > ${D}${nonarch_base_libdir}/udev/rules.d/70-kaonic-rf215.rules
    chmod 0644 ${D}${nonarch_base_libdir}/udev/rules.d/70-kaonic-rf215.rules

    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/kaonic-rf215-update ${D}${sbindir}/kaonic-rf215-update
}
