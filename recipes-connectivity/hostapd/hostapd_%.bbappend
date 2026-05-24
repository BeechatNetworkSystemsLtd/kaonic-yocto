SUMMARY = "Hostapd daemon"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://hostapd/README;md5=8aa4bc8523e30f0eb2453c4fcbcef5ca"

require hostapd.inc

SRC_URI:append = " file://hostapd.service"

SYSTEMD_SERVICE:${PN} = "hostapd.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += "${systemd_system_unitdir}"

do_install:append() {
    sed -i 's/^ssid=test$/ssid=Kaonic-1S/' ${D}${sysconfdir}/hostapd.conf
    if ! grep -q '^ssid=Kaonic-1S$' ${D}${sysconfdir}/hostapd.conf; then
        bbfatal "Expected default hostapd SSID line was not updated"
    fi
}
