DESCRIPTION = "Kaonic Radio Package" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd wpa-supplicant"

DEPENDS += "cargo-bin-cross-${TARGET_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

INSANE_SKIP:${PN} += "already-stripped"

inherit cargo_bin systemd pkgconfig

PR = "r2" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-radio.git;protocol=https;branch=main;"
SRCREV = "691924287c9fdb2bb52c6737965933ec856a3fdb"

SRC_URI += " \
    file://wifi_connect.sh \
    file://wifi_mode.sh \
    file://kaonic-wifi-mode.service \
"

do_compile[network] = "1"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-commd.service kaonic-factory.service kaonic-wifi-mode.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    ${bindir}/kaonic-wifi-mode \
    /home/root/wifi_connect.sh \
    /home/root/wifi_mode.sh \
    ${systemd_system_unitdir}/kaonic-wifi-mode.service \
    ${systemd_system_unitdir}/kaonic-commd.service \
    ${systemd_system_unitdir}/kaonic-factory.service \
    /etc/kaonic/kaonic_machine \
    /etc/kaonic/beechat-ota.pub.pem \
    /etc/kaonic/plugins \
    /etc/kaonic/plugins/kaonic-commd \
    /etc/kaonic/plugins/kaonic-factory \
"

S = "${WORKDIR}/git"

do_install() {
    # Kaonic commd
    install -d ${D}${bindir}

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-wifi-mode.service ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/kaonic-commd/kaonic-commd.service ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/kaonic-factory/kaonic-factory.service ${D}${systemd_system_unitdir}

    # Help scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/wifi_mode.sh ${D}${bindir}/kaonic-wifi-mode

    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh
    install -m 0755  ${WORKDIR}/wifi_mode.sh ${D}/home/root/wifi_mode.sh

    install -d ${D}/etc/kaonic
    install -d ${D}/etc/kaonic/plugins
    install -d ${D}/etc/kaonic/plugins/kaonic-commd/current
    install -d ${D}/etc/kaonic/plugins/kaonic-factory/current

    echo ${MACHINE} > ${D}/etc/kaonic/kaonic_machine

    install -m 0644 ${S}/kaonic-commd/kaonic-plugin.toml ${D}/etc/kaonic/plugins/kaonic-commd/kaonic-plugin.toml
    install -m 0644 ${S}/kaonic-commd/kaonic-commd.service ${D}/etc/kaonic/plugins/kaonic-commd/kaonic-commd.service
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-commd ${D}/etc/kaonic/plugins/kaonic-commd/current/kaonic-commd
    sha256sum ${D}/etc/kaonic/plugins/kaonic-commd/current/kaonic-commd | awk '{print $1}' > ${D}/etc/kaonic/plugins/kaonic-commd/kaonic-commd.sha256
    ln -sf /etc/kaonic/plugins/kaonic-commd/current/kaonic-commd ${D}${bindir}/kaonic-commd

    install -m 0644 ${S}/kaonic-factory/kaonic-plugin.toml ${D}/etc/kaonic/plugins/kaonic-factory/kaonic-plugin.toml
    install -m 0644 ${S}/kaonic-factory/kaonic-factory.service ${D}/etc/kaonic/plugins/kaonic-factory/kaonic-factory.service
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-factory ${D}/etc/kaonic/plugins/kaonic-factory/current/kaonic-factory
    sha256sum ${D}/etc/kaonic/plugins/kaonic-factory/current/kaonic-factory | awk '{print $1}' > ${D}/etc/kaonic/plugins/kaonic-factory/kaonic-factory.sha256
    ln -sf /etc/kaonic/plugins/kaonic-factory/current/kaonic-factory ${D}${bindir}/kaonic-factory

    install -m 0644 ${S}/certs/beechat-ota.pub.pem ${D}/etc/kaonic/
}
