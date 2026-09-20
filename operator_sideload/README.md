# 9/19 arm64 sideload

Cursor will not open a 119MB APK. The build is **15 files**, 8MB each:

`AEGIS_SEP19_ARM64.part00` … `AEGIS_SEP19_ARM64.part14`

Join them on a computer, then install the APK.

Windows (in this folder):

    join_windows.bat

Mac / Linux (in this folder):

    sh join_mac_linux.sh

That writes `AEGIS_SEP19_ARM64.apk`. Do not git-add the parts or the APK.
