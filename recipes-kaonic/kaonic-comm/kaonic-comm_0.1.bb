DESCRIPTION = "Kaonic Radio Package" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd"

DEPENDS += "cargo-bin-cross-${TARGET_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

INSANE_SKIP:${PN} += "already-stripped"

inherit cargo_bin systemd pkgconfig

PR = "r0" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-radio.git;protocol=https;branch=main;"
SRCREV = "0439489a542e9815e0a3cd6bfea25502909013fa"

SRC_URI += " \
    file://wifi_connect.sh \
    file://kaonic-commd.service \
    file://kaonic-factory.service \
"

do_compile[network] = "1"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-commd.service kaonic-factory.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    /home/root/wifi_connect.sh \
    ${systemd_system_unitdir}/kaonic-commd.service \
    ${systemd_system_unitdir}/kaonic-factory.service \
"

S = "${WORKDIR}/git"

do_install() {
    # Kaonic commd
    install -d ${D}${bindir}
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-commd ${D}${bindir}/kaonic-commd
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-factory ${D}${bindir}/kaonic-factory

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-commd.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-factory.service ${D}${systemd_system_unitdir}

    # Help scripts
    install -d ${D}/home/root
    install -m 0755  ${WORKDIR}/wifi_connect.sh ${D}/home/root/wifi_connect.sh

    install -d ${D}/etc/kaonic

    echo ${MACHINE} > ${D}/etc/kaonic/kaonic_machine

    # Write version from git tag (falls back to SRCREV short hash if no tag)
    cd ${S}
    GIT_VERSION=$(git describe --tags --always 2>/dev/null || echo "${SRCREV}" | cut -c1-8)
    echo "${GIT_VERSION}" > ${D}/etc/kaonic/kaonic-commd.version

    # Write sha256 of the installed binary
    sha256sum ${D}${bindir}/kaonic-commd | awk '{print $1}' > ${D}/etc/kaonic/kaonic-commd.sha256

    install -m 0644 ${S}/certs/beechat-ota.pub.pem ${D}/etc/kaonic/
}

