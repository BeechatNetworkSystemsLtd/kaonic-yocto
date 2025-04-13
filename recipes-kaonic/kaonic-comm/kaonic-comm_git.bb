DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=70eac050876ed2e265e3deee01ec75cd"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit pkgconfig cmake

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-comm.git;protocol=https;branch=main;"
SRCREV = "260db9e93f3f600884f1c0a7f5576c63aeb89db6"

SRC_URI += " file://wifi_connect.sh"

FILES:${PN} += " \
    /home/root/*.sh \
"

S = "${WORKDIR}/git"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/bin/kaonic-commd ${D}${bindir}/kaonic-commd

    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh
}
