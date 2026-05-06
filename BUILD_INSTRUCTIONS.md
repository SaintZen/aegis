# Build Instructions - Latest Version with New Features

## What's New in This Build

✅ **Safe Place Screen:**
- Added third video: `mountain_bell.mp4` (looks for `mountain_bell` or `gallery_3` in res/raw/)
- Added page indicator dots at the bottom (3 dots for 3 videos)
- Fixed page navigation to handle all 3 videos
- Dots hidden in landscape mode, visible in portrait

✅ **Exercises:**
- Already implemented (QuickExerciseSelectorActivity)

## To Build the Latest APK

**Option 1: Use the install script (builds and installs to phone):**
```cmd
cd AnxietyAnchor
.\install-to-phone.bat
```

**Option 2: Just build (creates APK file):**
```cmd
cd AnxietyAnchor
.\build.bat
```

**Option 3: Use Gradle directly:**
```cmd
cd AnxietyAnchor
gradle-7.5\bin\gradle.bat assembleDebug -x lint --no-daemon
```

## Output Location

The APK will be created at:
`AnxietyAnchor\app\build\outputs\apk\debug\app-debug.apk`

## Important Notes

1. **Video File Required:** 
   - Make sure `mountain_bell.mp4` (or `gallery_3.mp4`) exists in `AnxietyAnchor\app\src\main\res\raw\`
   - If the file is missing, the third video won't appear (but app won't crash)

2. **Version:** 2.6.1 (versionCode 31)

3. **Current Time:** The latest APK before these changes was built at 1pm today. This new build will include all the updates.

