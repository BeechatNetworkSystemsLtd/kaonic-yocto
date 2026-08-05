FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:stm32mp1-kaonic1s-r30 = " file://kaonic-dfu-button.cfg"
SRC_URI:append:stm32mp1-kaonic1s-r30 = " file://0001-gpio-keep-devicetree-bias-flags.patch"

do_configure:append() {
    fragment="${WORKDIR}/kaonic-dfu-button.cfg"
    [ -f "${fragment}" ] || return 0

    found=0
    for config in $(find ${B} -maxdepth 2 -name .config); do
        builddir=$(dirname ${config})
        grep -v '^#' ${fragment} | grep -v '^$' >> ${config}
        oe_runmake -C ${S} O=${builddir} olddefconfig
        found=1
    done

    if [ ${found} -eq 0 ]; then
        bbfatal "kaonic-dfu-button.cfg was not applied: no .config under ${B}"
    fi
}
