# The first-boot resize checks each file system without a bad-block read: SD cards and eMMC
# remap bad blocks themselves, and the read of a large userfs takes half an hour.
do_install:append() {
    sed -i 's/ -f -y -c -C 0 / -f -y -C 0 /' ${D}/init.d/95-resize
    if grep -q -- ' -c -C 0 ' ${D}/init.d/95-resize; then
        bbfatal "init-resize.sh changed: the bad-block read is still there"
    fi
}
