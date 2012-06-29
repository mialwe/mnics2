#!/sbin/busybox sh
#
# this starts the initscript processing and writes log messages
# and/or error messages for debugging of kernel initscripts or
# user/init.d-scripts.
#

# SETUP ------------------------------------------------------------------------
# set busybox location
BB="/sbin/busybox"

# backup and clean logfile
cp /data/user.log /data/last_user.log
rm /data/user.log

# start logging
exec >>/data/user.log
exec 2>&1

# INSTALLER --------------------------------------------------------------------
echo "remounting /system readwrite..."
/sbin/busybox mount -o remount,rw /system

# create xbin
if $BB [ -d /system/xbin ];then
    echo "/system/xbin found, skipping mkdir..."
else
    echo "/system/xbin not found, creating..."
    $BB mkdir /system/xbin
    $BB chmod 755 /system/xbin
fi

# create init.d
if $BB [ -d /system/etc/init.d ];then
    echo "/system/etc/init.d found, skipping mkdir..."
else
    echo "/system/etc/init.d not found, creating..."
    $BB mkdir /system/etc/init.d
    $BB chmod 777 /system/etc/init.d
fi

# clean multiple su binaries
echo "cleaning su/Superuser installations..."
$BB rm -f /system/bin/su
$BB rm -f /vendor/bin/su
$BB rm -f /system/sbin/su
$BB rm -f /system/xbin/su
$BB rm -f /system/app/Superuser.apk
$BB rm -f /data/app/Superuser.apk

# install xbin/su if not there
echo "installing su binary..."
$BB cat /res/misc/su > /system/xbin/su
$BB chown 0.0 /system/xbin/su
$BB chmod 4755 /system/xbin/su

# install /system/app/Superuser.apk if not there
echo "installing /system/app/Superuser.apk..."
$BB cat /res/misc/Superuser.apk > /system/app/Superuser.apk
$BB chown 0.0 /system/app/Superuser.apk
$BB chmod 644 /system/app/Superuser.apk

echo "installing BLN lights.exynos4.so..."
$BB cat /res/misc/lights.exynos4.so > /system/lib/hw/lights.exynos4.so
$BB chown 0.0 /system/lib/hw/lights.exynos4.so
$BB chmod 644 /system/lib/hw/lights.exynos4.so


echo "remounting /system readonly..."
/sbin/busybox mount -o remount,ro /system

# START ------------------------------------------------------------------------
echo
echo "************************************************"
echo "MNICS2 BOOT LOG"
echo "************************************************"
echo
echo "$(date)"
echo
# log basic system information
echo -n "Kernel: ";$BB uname -r
echo -n "PATH: ";echo $PATH
echo -n "ROM: ";cat /system/build.prop|$BB grep ro.build.display.id
echo -n "BusyBox:";$BB|$BB grep BusyBox

if $BB [ -f /boot.txt ];then
    echo;echo "----------------------------------------"
    echo;echo "$(date) init bootlog"
    cat /boot.txt
    echo;echo "----------------------------------------"
fi

echo;echo "$(date) modules"
ls -l /lib/modules

echo;echo "$(date) modules loaded"
$BB lsmod
echo

# print file contents <string messagetext><file output>
cat_msg_sysfile() {
    MSG=$1
    SYSFILE=$2
    echo -n "$MSG"
    cat $SYSFILE
}

# partitions
echo; echo "$(date) mount"
for i in $($BB mount | $BB grep relatime | $BB cut -d " " -f3);do
    $BB mount -o remount,noatime $i
done
for i in $(/sbin/busybox mount | /sbin/busybox grep ext4 | /sbin/busybox cut -d " " -f3); do
    sync
    $BB mount -o remount,commit=20 $i
done
mount

# vm tweaks
echo; echo "$(date) vm"
echo "0" > /proc/sys/vm/swappiness                   # Not really needed as no /swap used...
echo "1500" > /proc/sys/vm/dirty_writeback_centisecs # Flush after 20sec. (o:500)
echo "1500" > /proc/sys/vm/dirty_expire_centisecs    # Pages expire after 20sec. (o:200)
echo "5" > /proc/sys/vm/dirty_background_ratio       # flush pages later (default 5% active mem)
echo "15" > /proc/sys/vm/dirty_ratio                 # process writes pages later (default 20%)  
echo "3" > /proc/sys/vm/page-cluster
echo "0" > /proc/sys/vm/laptop_mode
echo "0" > /proc/sys/vm/oom_kill_allocating_task
echo "0" > /proc/sys/vm/panic_on_oom
echo "1" > /proc/sys/vm/overcommit_memory
cat_msg_sysfile "swappiness: " /proc/sys/vm/swappiness                   
cat_msg_sysfile "dirty_writeback_centisecs: " /proc/sys/vm/dirty_writeback_centisecs
cat_msg_sysfile "dirty_expire_centisecs: " /proc/sys/vm/dirty_expire_centisecs    
cat_msg_sysfile "dirty_background_ratio: " /proc/sys/vm/dirty_background_ratio
cat_msg_sysfile "dirty_ratio: " /proc/sys/vm/dirty_ratio 
cat_msg_sysfile "page-cluster: " /proc/sys/vm/page-cluster
cat_msg_sysfile "laptop_mode: " /proc/sys/vm/laptop_mode
cat_msg_sysfile "oom_kill_allocating_task: " /proc/sys/vm/oom_kill_allocating_task
cat_msg_sysfile "panic_on_oom: " /proc/sys/vm/panic_on_oom
cat_msg_sysfile "overcommit_memory: " /proc/sys/vm/overcommit_memory

# security enhancements
# rp_filter must be reset to 0 if TUN module is used (issues)
echo; echo "$(date) sec"
echo 0 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo -n "SEC: ip_forward :";cat /proc/sys/net/ipv4/ip_forward
echo -n "SEC: rp_filter :";cat /proc/sys/net/ipv4/conf/all/rp_filter
echo -n "SEC: use_tempaddr :";cat /proc/sys/net/ipv6/conf/all/use_tempaddr
echo -n "SEC: accept_source_route :";cat /proc/sys/net/ipv4/conf/all/accept_source_route
echo -n "SEC: send_redirects :";cat /proc/sys/net/ipv4/conf/all/send_redirects
echo -n "SEC: icmp_echo_ignore_broadcasts :";cat /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 

# setprop tweaks
echo; echo "$(date) prop"
setprop wifi.supplicant_scan_interval 180
echo -n "wifi.supplicant_scan_interval (is this actually used?): ";getprop wifi.supplicant_scan_interval

# kernel tweaks
echo; echo "$(date) kernel"
echo "NO_GENTLE_FAIR_SLEEPERS" > /sys/kernel/debug/sched_features
echo 3000000 > /proc/sys/kernel/sched_latency_ns
echo 500000 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns
echo 0 > /proc/sys/kernel/panic_on_oops
echo 0 > /proc/sys/kernel/panic
cat_msg_sysfile "sched_features: " /sys/kernel/debug/sched_features
cat_msg_sysfile "sem: " /proc/sys/kernel/sem; 
cat_msg_sysfile "sched_latency_ns: " /proc/sys/kernel/sched_latency_ns
cat_msg_sysfile "sched_wakeup_granularity_ns: " /proc/sys/kernel/sched_wakeup_granularity_ns
cat_msg_sysfile "sched_min_granularity_ns: " /proc/sys/kernel/sched_min_granularity_ns
cat_msg_sysfile "panic_on_oops: " /proc/sys/kernel/panic_on_oops
cat_msg_sysfile "panic: " /proc/sys/kernel/panic

# set sdcard read_ahead
echo; echo "$(date) read_ahead_kb"
echo "256" > /sys/devices/virtual/bdi/default/read_ahead_kb
echo "256" > /sys/block/mmcblk0/bdi/read_ahead_kb
echo "256" > /sys/block/mmcblk1/bdi/read_ahead_kb
cat_msg_sysfile "default: " /sys/devices/virtual/bdi/default/read_ahead_kb
cat_msg_sysfile "0: " /sys/block/mmcblk0/bdi/read_ahead_kb
cat_msg_sysfile "1: " /sys/block/mmcblk1/bdi/read_ahead_kb

echo; echo "$(date) io"
LOOP=`$BB ls -d /sys/block/loop*`
MMC=`$BB ls -d /sys/block/mmc*`

# general IO tweaks
for i in $MMC;do
    echo 0 > $i/queue/rotational
    echo 0 > $i/queue/iostats
    echo 1024 > $i/queue/nr_requests
done

# init.d support, executes all /system/etc/init.d/<S>scriptname files
echo;echo "$(date) init.d/userinit.d"
if $BB [ -f /data/local/.mn_activateinitd ];then
    echo $(date) USER INIT START from /system/etc/init.d
    if cd /system/etc/init.d >/dev/null 2>&1 ; then
        for file in S* ; do
            if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
            echo "/system/etc/init.d: START '$file'"
            /system/bin/sh "$file"
            echo "/system/etc/init.d: EXIT '$file' ($?)"
        done
    fi
    echo $(date) USER INIT DONE from /system/etc/init.d
    echo $(date) USER INIT START from /data/local/userinit.d
    if cd /data/local/userinit.d >/dev/null 2>&1 ; then
        for file in S* ; do
            if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
            echo "/data/local/userinit.d: START '$file'"
            /system/bin/sh "$file"
            echo "/data/local/userinit.d: EXIT '$file' ($?)"
        done
    fi
    echo $(date) USER INIT DONE from /data/local/userinit.d
else
    echo "/data/local/.mn_activateinitd not found, no init.d execution, skipping..."
fi
