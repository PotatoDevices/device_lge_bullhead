#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

################################################################################

# take the A57s offline when thermal hotplug is disabled
write /sys/devices/system/cpu/cpu4/online 0
write /sys/devices/system/cpu/cpu5/online 0

# disable thermal bcl hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# some files in /sys/devices/system/cpu are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
# Restorecon again to give new files the correct label.
restorecon -R /sys/devices/system/cpu

# Best effort limiting for first time boot if msm_performance module is absent
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 960000

# Limit A57 max freq from msm_perf module in case CPU 4 is offline
write /sys/module/msm_performance/parameters/cpu_max_freq "4:960000 5:960000"

# Disable CPU retention
write /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled 0

# Disable L2 retention
write /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled 0

# configure governor settings for little cluster
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 0
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 100
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 60000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_slack 30000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 0
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "29 384000:88 600000:90 787200:92 960000:93 1248000:98"
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 60000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 302000
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1440000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif 1

# online CPU4
write /sys/devices/system/cpu/cpu4/online 1

# configure governor settings for big cluster
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 0
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 100
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 30000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_slack 480000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 0
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads 98
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 30000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 302400
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 1958400
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/ignore_hispeed_on_notif 1

# restore A57's max
copy /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq

# plugin remaining A57s
write /sys/devices/system/cpu/cpu5/online 1

# Restore CPU 4 max freq from msm_performance
write /sys/module/msm_performance/parameters/cpu_max_freq "4:4294967295 5:4294967295"

# input boost configuration
write /sys/module/cpu_boost/parameters/input_boost_freq "0:1248000 4:672000"
write /sys/module/cpu_boost/parameters/input_boost_ms 1500

# Setting B.L scheduler parameters
write /proc/sys/kernel/sched_migration_fixup 1
write /proc/sys/kernel/sched_upmigrate 95
write /proc/sys/kernel/sched_downmigrate 85
write /proc/sys/kernel/sched_freq_inc_notify 400000
write /proc/sys/kernel/sched_freq_dec_notify 400000

#enable rps static configuration
write /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus 8

# android background processes are set to nice 10. Never schedule these on the a57s.
write /proc/sys/kernel/sched_upmigrate_min_nice 9

get-set-forall  /sys/class/devfreq/qcom,cpubw*/governor bw_hwmon

# Disable sched_boost
write /proc/sys/kernel/sched_boost 0

# re-enable thermal and BCL hotplug
write /sys/module/msm_thermal/core_control/enabled 1
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# set GPU default power level to 4 (305MHz) as it is smoother
write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 4
write /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz

# these minfree settings are set like this otherwise Android kills apps like Pokemon GO
# almost instantly after they go to the background. Even with KSM and ZRAM block of 1Gb
# it still happens. With these minfree settings (same parameters as the Nexus 5) the issue
# doesn't happen anymore	thanks to @franciscofranco
write /sys/module/lowmemorykiller/parameters/minfree "18432,23040,27648,32256,36864,46080"