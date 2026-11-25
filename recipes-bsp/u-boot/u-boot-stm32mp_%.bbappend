FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:stm32mp1-kaonic1s-r30 = " file://kaonic-dfu-button.cfg"
SRC_URI:append:stm32mp1-kaonic1s-r30 = " file://0001-gpio-keep-devicetree-bias-flags.patch"
SRC_URI:append:stm32mp1-kaonic1x-r09 = " file://0001-gpio-keep-devicetree-bias-flags.patch"

# A/B slots: the boot script that picks a slot, and the command it restarts
# the board with when neither can be booted. See conf/machine/include/kaonic-ab-slots.inc.
SRC_URI:append = " file://0002-stm32mp15-boot-from-A-B-slots.patch"
SRC_URI:append = " file://kaonic-ab-slots.cfg"

# Config fragments, applied to every U-Boot configuration built.
do_configure:append() {
    found=0
    for config in $(find ${B} -maxdepth 2 -name .config); do
        builddir=$(dirname ${config})
        for fragment in ${WORKDIR}/kaonic-*.cfg; do
            [ -f "${fragment}" ] || continue
            grep -v '^#' ${fragment} | grep -v '^$' >> ${config}
        done
        oe_runmake -C ${S} O=${builddir} olddefconfig
        found=1
    done

    if [ ${found} -eq 0 ]; then
        bbfatal "U-Boot config fragments were not applied: no .config under ${B}"
    fi
}
