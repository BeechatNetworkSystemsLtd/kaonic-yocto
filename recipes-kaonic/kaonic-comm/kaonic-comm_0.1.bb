DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=70eac050876ed2e265e3deee01ec75cd"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit pkgconfig cmake systemd

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-comm.git;protocol=https;branch=main;"
SRCREV = "e3871b8d25a601bb1dffd5ca9027971142615cce"

SRC_URI += " \
    file://wifi_connect.sh \
    file://kaonic-commd.service \
"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-commd.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    /home/root/wifi_connect.sh \
    ${systemd_system_unitdir}/kaonic-commd.service \
"

S = "${WORKDIR}/git"

do_install:append() {
    # Kaonic commd
    install -d ${D}${bindir}
    install -m 0755 ${B}/bin/kaonic-commd ${D}${bindir}/kaonic-commd

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-commd.service ${D}${systemd_system_unitdir}

    # Help scripts
    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh

    install -d ${D}/etc/kaonic
    echo ${MACHINE} > ${D}/etc/kaonic/kaonic_machine
}

