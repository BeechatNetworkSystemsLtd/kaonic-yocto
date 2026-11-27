# A/B slots: /boot is the running slot's bootfs, as kaonic.slot on the command line names it.
kaonic_slot=$(sed -n 's/.*kaonic\.slot=\([ab]\).*/\1/p' /proc/cmdline)
[ -n "$kaonic_slot" ] && MOUNT_PARTITIONS_LIST=$(echo "$MOUNT_PARTITIONS_LIST" | sed "s/ bootfs,/ bootfs_${kaonic_slot},/")
