#!/usr/bin/bash
[[ "$(adb devices 2>&1 | tail -n2)" == 'List of devices attached' ]] && echo "No phone connected." >&2 && exit 1
exit 0