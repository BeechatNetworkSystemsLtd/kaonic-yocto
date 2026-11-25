SUMMARY = "Kaonic login user, shell prompt and login banner"
DESCRIPTION = "Adds the admin user with passwordless sudo and a view-only \
user without it, a coloured prompt (admin in yellow, the view-only user in \
green, root in red), a short login banner with OS and board details, and \
makes the serial console log in as admin instead of root."

SECTION = "kaonic"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://kaonic-prompt.sh \
    file://kaonic-motd.sh \
    file://kaonic.sudoers \
    file://kaonic.bashrc \
    file://kaonic.profile \
    file://serial-getty-autologin.conf \
"

S = "${WORKDIR}"

KAONIC_USER ?= "admin"
# Empty: no password. Otherwise a crypt hash (openssl passwd -6), $ as \$.
KAONIC_USER_PASSWORD ?= ""

# View-only: no sudo, can read the journal.
KAONIC_VIEWER ?= "user"
KAONIC_VIEWER_PASSWORD ?= ""

# Banner copyright year.
KAONIC_BUILD_YEAR = "${@d.getVar('DATE')[0:4]}"

inherit useradd

USERADD_PACKAGES = "${PN}"
# Also made by systemd, but too late for useradd.
GROUPADD_PARAM:${PN} = "--system systemd-journal"
# Homes come from this package: the skel .bashrc would override the prompt.
USERADD_PARAM:${PN} = " \
    --home-dir /home/${KAONIC_USER} --no-create-home \
    --user-group --shell ${bindir}/bash \
    --groups sudo,audio,video,dialout,plugdev \
    --password '${KAONIC_USER_PASSWORD}' \
    ${KAONIC_USER}; \
    --home-dir /home/${KAONIC_VIEWER} --no-create-home \
    --user-group --shell ${bindir}/bash \
    --groups systemd-journal \
    --password '${KAONIC_VIEWER_PASSWORD}' \
    ${KAONIC_VIEWER} \
"

do_install() {
    install -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${S}/kaonic-prompt.sh ${D}${sysconfdir}/profile.d/kaonic-prompt.sh
    # zz-: runs after the other profile.d scripts.
    sed "s/@BUILD_YEAR@/${KAONIC_BUILD_YEAR}/" ${S}/kaonic-motd.sh \
        > ${D}${sysconfdir}/profile.d/zz-kaonic-motd.sh
    chmod 0644 ${D}${sysconfdir}/profile.d/zz-kaonic-motd.sh

    install -d -m 0750 ${D}${sysconfdir}/sudoers.d
    install -m 0440 ${S}/kaonic.sudoers ${D}${sysconfdir}/sudoers.d/kaonic

    for u in ${KAONIC_USER} ${KAONIC_VIEWER}; do
        install -d -m 0750 -o $u -g $u ${D}/home/$u
        install -m 0644 -o $u -g $u ${S}/kaonic.bashrc ${D}/home/$u/.bashrc
        install -m 0644 -o $u -g $u ${S}/kaonic.profile ${D}/home/$u/.profile
    done

    install -d ${D}${systemd_system_unitdir}/serial-getty@.service.d
    sed 's/@KAONIC_USER@/${KAONIC_USER}/' ${S}/serial-getty-autologin.conf \
        > ${D}${systemd_system_unitdir}/serial-getty@.service.d/kaonic-autologin.conf
    chmod 0644 ${D}${systemd_system_unitdir}/serial-getty@.service.d/kaonic-autologin.conf
}

FILES:${PN} += " \
    /home/${KAONIC_USER} \
    /home/${KAONIC_VIEWER} \
    ${systemd_system_unitdir}/serial-getty@.service.d \
"

RDEPENDS:${PN} += "bash sudo"
