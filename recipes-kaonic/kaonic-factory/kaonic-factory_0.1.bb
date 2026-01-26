DESCRIPTION = "Kaonic Factory" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit cargo systemd cargo-update-recipe-crates pkgconfig

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-radio.git;protocol=https;branch=main;"
SRCREV = "0876dba3a44c18d5e91ac95bf589daf8ce937e73"

SRC_URI += " \
    file://kaonic-factory.service \
"

S = "${WORKDIR}/git"

require ${BPN}-crates.inc

CARGO_SRC_DIR = "kaonic-factory"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-factory.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    ${systemd_system_unitdir}/kaonic-factory.service \
"

S = "${WORKDIR}/git"

do_install:append() {
    # Kaonic factory daemon
    install -d ${D}${bindir}
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/kaonic-factory ${D}${bindir}/kaonic-factory

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-factory.service ${D}${systemd_system_unitdir}
}


