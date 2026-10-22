#!/usr/bin/bash
adb_is_phone_connected.sh || exit 1
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell settings put global stay_on_while_plugged_in 1
adb shell pm grant com.arlosoft.macrodroid android.permission.WRITE_SECURE_SETTINGS
adb kill-server