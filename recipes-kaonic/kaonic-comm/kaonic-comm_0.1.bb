DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=70eac050876ed2e265e3deee01ec75cd"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd python3-cryptography python3-flask"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit pkgconfig cmake systemd

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-comm.git;protocol=https;branch=main;"
SRCREV = "f3e7edd277fe35ff3c0e5aa7e3554536482ab894"

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

S = "${WORKDIR}/git"

do_compile:append() {
    cd ${S}
    mkdir -p ${B}/deploy
    python3 ${S}/scripts/create-ota.py -b ${B} -o ${B}/deploy -k
}

do_install:append() {
    # Kaonic commd
    install -d ${D}${bindir}
    install -m 0755 ${B}/bin/kaonic-commd ${D}${bindir}/kaonic-commd
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

