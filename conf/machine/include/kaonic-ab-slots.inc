# A/B slots: two bootfs/rootfs pairs, one of which is booted, so a system
# update is written to the other and the board falls back if it does not boot.
#
# Layout, in flash order:
#
#   fsbl1, fsbl2, metadata1/2, fip-a, fip-b, u-boot-env   as ST defines them
#   bootfs_a   64 MB    kernel, device trees, extlinux
#   bootfs_b   64 MB    same, empty from the factory
#   vendorfs   16 MB
#   rootfs_a   4 GB
#   rootfs_b   4 GB     empty from the factory
#   userfs     rest     data that survives updates; grown to the device on
#                       first boot by the resize initrd
#
# The factory image fills slot A only. U-Boot picks the slot (see the
# kaonic-ab-slots patch in recipes-bsp/u-boot) and the kernel is told which one
# through root=PARTLABEL=rootfs_<slot> and kaonic.slot=<slot>, so one bootfs
# image serves both slots.

KAONIC_SLOT_BOOTFS_SIZE ?= "${STM32MP_BOOTFS_SIZE}"
# In KB: 4 GB, the size the single rootfs partition had before.
KAONIC_SLOT_ROOTFS_SIZE ?= "4194304"

# One of ST's partition image entries, placed under a slot's label.
def kaonic_slot_partition(d, config, label, size):
    entry = partImage2partConfig(d, config, d.getVar('PARTITIONS_SUFFIX')).split(',')
    return ','.join([entry[0], label, size, entry[3], entry[4]])

# <binary_name>,<partlabel>,<size>,<type>,<copy>
KAONIC_SLOT_PARTITIONS_CONFIG = "\
    ${@kaonic_slot_partition(d, 'bootfs', 'bootfs_a', '${KAONIC_SLOT_BOOTFS_SIZE}')} \
    none,bootfs_b,${KAONIC_SLOT_BOOTFS_SIZE},System,1 \
    ${@partImage2partConfig(d, 'vendorfs', '${PARTITIONS_SUFFIX}')} \
    ${@kaonic_slot_partition(d, 'rootfs', 'rootfs_a', '${KAONIC_SLOT_ROOTFS_SIZE}')} \
    none,rootfs_b,${KAONIC_SLOT_ROOTFS_SIZE},FileSystem,1 \
    ${@partImage2partConfig(d, 'userfs', '${PARTITIONS_SUFFIX}')} \
    "

PARTITIONS_CONFIG[emmc] = "${KAONIC_SLOT_PARTITIONS_CONFIG}"
PARTITIONS_CONFIG[sdcard] = "${KAONIC_SLOT_PARTITIONS_CONFIG}"

# Created but not programmed, like fip-b and u-boot-env.
FLASHLAYOUT_PARTITION_ENABLE:bootfs_b = "PED"
FLASHLAYOUT_PARTITION_ENABLE:rootfs_b = "PED"

# ST caps the eMMC layout at 4 GB; two slots need more. 14 GB is below the
# user area of any 16 GB part.
DEVICE_MAX_OFFSET:EMMC = "0x380000000"

# The root is named by its partition label, which U-Boot fills in for the slot
# it chose; both the kernel and the resize initrd resolve PARTLABEL=.
UBOOT_EXTLINUX_ROOT:target-emmc = "root=PARTLABEL=${kaonic_root}"
UBOOT_EXTLINUX_ROOT:target-sdcard = "root=PARTLABEL=${kaonic_root}"
UBOOT_EXTLINUX_KERNEL_ARGS:append = " kaonic.slot=${kaonic_slot}"
