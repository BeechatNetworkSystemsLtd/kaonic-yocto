DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
DEPENDS:append = " python3-cryptography-native"
RDEPENDS:${PN} += "systemd python3-cryptography python3-flask"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit cargo systemd cargo-update-recipe-crates pkgconfig

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-radio.git;protocol=https;branch=main;"
SRCREV = "1f9c3db1ff83530bfd27e8f48065417e600197ee"

SRC_URI += " \
    file://wifi_connect.sh \
    file://kaonic-commd.service \
    file://kaonic-ota.service \
"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-commd.service kaonic-ota.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    /home/root/wifi_connect.sh \
    ${systemd_system_unitdir}/kaonic-commd.service \
    ${systemd_system_unitdir}/kaonic-ota.service \
"

CARGO_SRC_DIR = "kaonic-commd"

S = "${WORKDIR}/git"

require ${BPN}-crates.inc

do_compile:append() {
    cd ${S}
    mkdir -p ${B}/deploy
    export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
    python3 ${S}/scripts/create-ota.py -b ${B}/target/${CARGO_TARGET_SUBDIR} -o ${B}/deploy -k
}

do_install:append() {
    # Kaonic commd
    install -d ${D}${bindir}
    install -m 0755 ${B}/target/${CARGO_TARGET_SUBDIR}/kaonic-commd ${D}${bindir}/kaonic-commd
    install -m 0755 ${S}/ota/kaonic-ota.py ${D}${bindir}/kaonic-ota.py

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-commd.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-ota.service ${D}${systemd_system_unitdir}

    # Help scripts
    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh

    install -d ${D}/etc/kaonic

    echo ${MACHINE} > ${D}/etc/kaonic/kaonic_machine

    install -m 0755  ${B}/deploy/kaonic-comm-ota/kaonic-commd.version ${D}/etc/kaonic/
    install -m 0755  ${B}/deploy/kaonic-comm-ota/kaonic-commd.sha256 ${D}/etc/kaonic/
    install -m 0755  ${S}/certs/beechat-ota.pub.pem ${D}/etc/kaonic/
}

