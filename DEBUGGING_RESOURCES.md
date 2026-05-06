# Debugging Resources Guide

## Issue: Assets Not Working
Vault door, affirmations, and frost screen images not appearing.

## Assets Verified in Project

### ✅ Vault Door Video
- **File:** `app/src/main/res/raw/vault_door.mp4` (5.31 MB)
- **Code lookup:** `resources.getIdentifier("vault_door", "raw", packageName)`
- **Android strips extensions:** `vault_door.mp4` → resource name `"vault_door"` ✓

### ✅ Affirmation Voices  
- **Files:** 30 files in `app/src/main/res/raw/`
  - `vo_selfworth_01.mp3` through `vo_hope_05.mp3`
- **Code lookup:** `resources.getIdentifier("vo_${category}_${index}", "raw", packageName)`
- **Example:** `vo_selfworth_01.mp3` → resource name `"vo_selfworth_01"` ✓

### ❌ Frost Screen Images
- **Files:** NOT FOUND in `app/src/main/res/drawable/`
- **Expected:** `frost_screen_01.jpg` through `frost_screen_19.jpg`
- **Code lookup:** `resources.getIdentifier("frost_screen_${index}", "drawable", packageName)`
- **Status:** ❌ Images need to be added to drawable folder

## How to Debug on Device

### Check Logcat for Resource Lookups

1. **Connect device via USB**
2. **Enable USB debugging** on device
3. **Run logcat:**
   ```bash
   adb logcat | grep -E "(WorryVault|Affirmations|FrostScreen)"
   ```

### Expected Log Messages

#### Vault Door (Opening):
```
D/WorryVault: Looking for vault_door resource: resId=2131755000
D/WorryVault: Setting video URI: android.resource://com.anxietyanchor/2131755000
D/WorryVault: Vault door video prepared successfully (duration=5000ms)
```

#### Affirmations:
```
D/Affirmations: Looking for voice file: vo_selfworth_01 (resId: 2131755001)
D/Affirmations: Category: Self-Worth, Index: 1, Filename: vo_selfworth_01
D/Affirmations: Creating MediaPlayer with resId: 2131755001 for file: vo_selfworth_01
D/Affirmations: Playing voice file: vo_selfworth_01
```

#### Frost Screen:
```
D/FrostScreen: Using frost_screen_05
```
OR if not found:
```
E/FrostScreen: Error loading frost_screen_05, trying fallback
```

### If Resources Return 0 (Not Found)

If `resId=0`, the resource is NOT in the APK. Check:

1. **Files exist in project?**
   ```bash
   ls app/src/main/res/raw/vault_door.mp4
   ls app/src/main/res/raw/vo_*.mp3
   ls app/src/main/res/drawable/frost_screen_*.jpg
   ```

2. **Clean rebuild:**
   ```bash
   gradle clean assembleDebug
   ```

3. **Check APK contents:**
   ```bash
   unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -E "(vault_door|vo_|frost_screen)"
   ```

4. **Verify resource names match:**
   - Android resource names = filename WITHOUT extension
   - `vault_door.mp4` → `"vault_door"` ✓
   - `vo_selfworth_01.mp3` → `"vo_selfworth_01"` ✓
   - `frost_screen_01.jpg` → `"frost_screen_01"` ✓

## Common Issues

### Issue 1: Resource ID is 0
**Cause:** File not packaged in APK or wrong path
**Fix:** 
- Verify file exists in `res/raw/` or `res/drawable/`
- Clean rebuild: `gradle clean assembleDebug`
- Check filename matches code (no typos)

### Issue 2: MediaPlayer fails
**Cause:** Corrupted file or unsupported format
**Fix:**
- Verify file plays in media player
- Check file isn't corrupted
- Ensure format is supported (MP4 for video, MP3 for audio)

### Issue 3: Images not found
**Cause:** Images not added to drawable folder
**Fix:**
- Add `frost_screen_01.jpg` through `frost_screen_19.jpg` to `app/src/main/res/drawable/`
- Rebuild APK
- Verify files are lowercase with underscores (no spaces, no dashes in middle)

## Next Steps

1. **Add frost_screen images** to `app/src/main/res/drawable/`
   - Files: `frost_screen_01.jpg` through `frost_screen_19.jpg`
   - Format: JPG or PNG
   - Naming: lowercase with underscores

2. **Install APK on device** and check logcat

3. **Report logcat output** if issues persist

