FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://kaonic-slot-bootfs.sh"

do_install:append() {
    for script in ${D}/${base_sbindir}/${MOUNT_BASENAME}.sh ${D}/${INIT_D_DIR}/${MOUNT_BASENAME}.sh; do
        [ -f "$script" ] || continue
        sed -i "/^MOUNT_PARTITIONS_LIST=/r ${WORKDIR}/kaonic-slot-bootfs.sh" "$script"
        grep -q kaonic_slot "$script" || bbfatal "mount-partitions.sh changed: the slot's bootfs is not chosen"
    done
}
