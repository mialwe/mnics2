#!/sbin/busybox sh

setprop persist.service.adb.enable 1
if /sbin/busybox [ -f "/cache/recovery/command" ];then
    /sbin/busybox ln -s /system/etc /etc
    /sbin/busybox mount /dev/block/mmcblk0p9 /system
    /sbin/recovery-samsung &
else
    /sbin/busybox ln -s /misc /etc
    /sbin/busybox umount /cache
    /sbin/recovery &
fi
