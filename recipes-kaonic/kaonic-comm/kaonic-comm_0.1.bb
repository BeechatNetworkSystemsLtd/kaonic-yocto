DESCRIPTION = "Kaonic Comm" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=70eac050876ed2e265e3deee01ec75cd"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit pkgconfig cmake systemd

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-comm.git;protocol=https;branch=main;"
SRCREV = "260db9e93f3f600884f1c0a7f5576c63aeb89db6"

SRC_URI += " \
    file://wifi_connect.sh \
    file://ip_forward.conf \
    file://hostapd.service \
    file://kaonic-boot.service \
    file://kaonic-commd.service \
"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
    kaonic-commd.service \
    hostapd.service \
"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    /home/root/*.sh \
    ${systemd_system_unitdir}/* \
    ${sysconfdir}/sysctl.d/* \
"

S = "${WORKDIR}/git"

do_install:append() {
    # Kaonic commd
    install -d ${D}${bindir}
    install -m 0755 ${B}/bin/kaonic-commd ${D}${bindir}/kaonic-commd

    # Systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hostapd.service ${D}${systemd_system_unitdir}/hostapd.service
    install -m 0644 ${WORKDIR}/kaonic-commd.service ${D}${systemd_system_unitdir}/kaonic-commd.service
    # install -m 0644 ${WORKDIR}/kaonic-boot.service ${D}${systemd_system_unitdir}/kaonic-boot.service

    install -d ${D}${sysconfdir}/sysctl.d
    install -m 0644 ${WORKDIR}/ip_forward.conf ${D}${sysconfdir}/sysctl.d/ip_forward.conf

    # Scripts
    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh
}
