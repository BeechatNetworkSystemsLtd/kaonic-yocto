DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=70eac050876ed2e265e3deee01ec75cd"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"

inherit pkgconfig cmake

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-comm.git;protocol=https;branch=main;"
SRCREV = "ab20e27526d4efba8e03bc67e03718d0c36352b2"

S = "${WORKDIR}/git"

EXTRA_OECMAKE += ' \
    -DKAONIC_RFA_GPIO_RST_CHIP="/dev/gpiochip3" \
    -DKAONIC_RFA_GPIO_RST_LINE="8" \
    -DKAONIC_RFA_GPIO_IRQ_CHIP="/dev/gpiochip3" \
    -DKAONIC_RFA_GPIO_IRQ_LINE="9" \
    -DKAONIC_RFA_SPI_PATH="/dev/spidev6.0" \
    -DKAONIC_RFB_GPIO_RST_CHIP="/dev/gpiochip4" \
    -DKAONIC_RFB_GPIO_RST_LINE="13" \
    -DKAONIC_RFB_GPIO_IRQ_CHIP="/dev/gpiochip4" \
    -DKAONIC_RFB_GPIO_IRQ_LINE="15" \
    -DKAONIC_RFB_SPI_PATH="/dev/spidev3.0" \
    -DKAONIC_SERIAL_TTY_PATH="/dev/ttyGS0" \
'

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/bin/kaonic-commd ${D}${bindir}/kaonic-commd
}
