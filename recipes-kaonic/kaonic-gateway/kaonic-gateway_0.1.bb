DESCRIPTION = "Kaonic Gateway" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=256737f5f795479e8ae7c476f5b9aeb0"

DEPENDS:append = " protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += " \
    systemd \
    iproute2 \
    iptables \
    iputils \
    procps \
    net-tools \
    iw \
    alsa-utils \
"

DEPENDS += "cargo-bin-cross-${TARGET_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

INSANE_SKIP:${PN} += "already-stripped"

inherit cargo_bin systemd pkgconfig

PR = "r3" 
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-gateway.git;protocol=https;branch=main;"
SRCREV = "a36ff32ee1e48d761a74c2745ed95c8f2658dbb3"

SRC_URI += " \
    file://kaonic-installer.service \
"

do_compile[network] = "1"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-gateway.service kaonic-installer.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    ${systemd_system_unitdir}/kaonic-gateway.service \
    ${systemd_system_unitdir}/kaonic-installer.service \
    /etc/kaonic/kaonic-gateway.version \
    /etc/kaonic/kaonic-gateway.sha256 \
    /etc/kaonic/plugins \
    /etc/kaonic/plugins/kaonic-gateway \
"

S = "${WORKDIR}/git"

do_install() {
    # Kaonic Gateway
    install -d ${D}${bindir}
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-installer ${D}${bindir}/kaonic-installer

    # Kaonic Gateway systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/kaonic-gateway/kaonic-gateway.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-installer.service ${D}${systemd_system_unitdir}

    cd ${S}
    install -d ${D}/etc/kaonic
    install -d ${D}/etc/kaonic/plugins
    install -d ${D}/etc/kaonic/plugins/kaonic-gateway/current
    install -m 0644 ${S}/kaonic-gateway/kaonic-plugin.toml ${D}/etc/kaonic/plugins/kaonic-gateway/kaonic-plugin.toml
    install -m 0644 ${S}/kaonic-gateway/kaonic-gateway.service ${D}/etc/kaonic/plugins/kaonic-gateway/kaonic-gateway.service
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-gateway ${D}/etc/kaonic/plugins/kaonic-gateway/current/kaonic-gateway
    sha256sum ${D}/etc/kaonic/plugins/kaonic-gateway/current/kaonic-gateway | awk '{print $1}' > ${D}/etc/kaonic/plugins/kaonic-gateway/kaonic-gateway.sha256

    ln -sf /etc/kaonic/plugins/kaonic-gateway/current/kaonic-gateway ${D}${bindir}/kaonic-gateway
}
