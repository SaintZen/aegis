# Anxiety Anchor v2.6 - Update Changelog

## 🎉 **Major New Features**

### 1. **Interactive Haptic Grounding (Frosted Glass)**
- **New Feature:** Touch-based grounding exercise
- **Location:** Safe Place → "Touch Grounding" button (formerly "5-4-3-2-1 Grounding")
- **Features:**
  - Frosted glass overlay effect
  - Rub the screen to reveal hidden calming images
  - Haptic feedback (vibration) on touch
  - Progress tracking (shows percentage revealed)
  - Completion detection (70%+ revealed)
  - Uses calming gallery images as background

### 2. **Worry Vault** 🔒
- **New Feature:** Secure worry storage with time limits
- **Location:** Anxiety Lab → Worry Vault
- **Features:**
  - **5-minute countdown timer** at the top
  - **Dark, high-security vault aesthetic** (black background, security-style UI)
  - **Dynamic font weight** - Text gets bolder as you type more
  - **Boredom detection** - If no input for 20 seconds, shows: "Are you bored yet? Maybe these worries aren't as powerful as you thought."
  - **Animated vault doors** - Two doors slam shut when timer ends or user exits
  - **Daily lockout** - Vault closes and blocks access until next calendar day (midnight reset)
  - **Local storage only** - All entries saved in SharedPreferences (no external database)
  - **Vault door image support** - Uses `vault_door.png` from drawable folder
  - **"View Entries" button** - Always accessible to view saved worries

### 3. **Anxiety Lab Hub** 🧪
- **New Feature:** Centralized hub for experimental anxiety tools
- **Location:** Main screen → "🧪 Anxiety Lab" button
- **Current Tools:**
  - Frost Screen (Frosted Glass Grounding)
  - Worry Vault
  - Externalizing the Monster (Coming Soon)
- **Purpose:** Consolidates experimental features in one place

---

## 🔄 **Reorganization & Improvements**

### 4. **Anxiety Logging Moved to Mood Check-In**
- **Change:** Anxiety Logging moved from Anxiety Lab to Mood Check-In tab
- **Reason:** Reduces clutter, groups tracking features together
- **Location:** Mood Check-In → Scroll to bottom → "Open Anxiety Log" button
- **Benefit:** Better organization, less duplication

### 5. **Enhanced Image Support**
- **Dynamic image detection** - Supports unlimited gallery images
- **Auto-detection:** App finds `gallery_1.png`, `gallery_2.png`, etc. automatically
- **Supports up to 20 images** (easily expandable)
- **Where used:**
  - Safe Place gallery
  - Calming Gallery
  - Frosted Glass Grounding backgrounds

### 6. **Pink/White Noise Toggle**
- **New Feature:** Toggle between White and Pink noise in Affirmations Library
- **Location:** Affirmations Library → Background Noise section
- **Features:**
  - White/Pink noise selector buttons
  - Automatically detects `white_noise.mp3` and `pink_noise.mp3` files
  - Falls back to ambient sounds if noise files don't exist
  - Volume set to 30% to avoid interfering with TTS

### 7. **Safe Place Landscape Mode**
- **Enhancement:** Full-screen landscape mode for Safe Place images
- **Feature:** When phone is turned sideways, image fills entire screen
- **Minimal overlay:** Thumbnails and controls at bottom
- **Better immersion:** Full-screen viewing experience

---

## 🎨 **Visual Improvements**

### 8. **Sleep-Friendly Colors**
- **6pm-6am mode:** Warmer colors (lavender, amber) during sleep hours
- **Dark mode updates:** Purple/lavender instead of blue to reduce blue light
- **Breathing circle:** Uses warm amber and soft lavender during sleep hours

### 9. **Affirmations Enhancements**
- **Color-coded sentences:** Each sentence in affirmations is color-coded
- **Larger text:** Increased to 22sp with bold styling
- **Better readability:** Improved line spacing and padding
- **White noise option:** Optional background sound while reading/listening

---

## 🔧 **Technical Improvements**

### 10. **Vault Door Image Support**
- **Custom image support:** Uses `vault_door.png` from drawable folder
- **Automatic detection:** App finds and uses vault door image if present
- **Fallback:** Shows lock emoji if image not found
- **Used in:**
  - Closing animation (left and right doors)
  - Closed vault view

### 11. **Improved Chart Rendering**
- **Progress Charts fixes:** Better error handling and fallback layouts
- **Chart visibility:** Ensured proper backgrounds and rendering
- **Data loading:** Improved logging and data validation

---

## 📦 **File Structure Changes**

### New Files Created:
- `WorryVaultActivity.kt` - Worry Vault feature
- `FrostedGlassGroundingActivity.kt` - Frosted Glass Grounding
- `FrostedGlassGroundingView.kt` - Custom view for frosted glass effect
- `AnxietyLabActivity.kt` - Anxiety Lab hub
- `activity_worry_vault.xml` - Worry Vault layout
- `activity_frosted_glass_grounding.xml` - Frosted Glass layout
- `activity_anxiety_lab.xml` - Anxiety Lab hub layout
- `layout-land/activity_safe_place.xml` - Landscape Safe Place layout

### Updated Files:
- `MoodCheckInActivity.kt` - Added Anxiety Logging button
- `SafePlaceActivity.kt` - Updated grounding button, landscape support
- `AffirmationsLibraryActivity.kt` - Added Pink/White noise toggle
- `PanicActivity.kt` - Updated Anxiety Lab button to launch hub
- `AndroidManifest.xml` - Registered new activities

---

## 🎯 **Summary of Changes**

**New Features:**
1. Interactive Haptic Grounding (Frosted Glass)
2. Worry Vault with 5-minute timer and daily lockout
3. Anxiety Lab Hub
4. Pink/White Noise Toggle

**Reorganization:**
- Anxiety Logging moved to Mood Check-In
- Anxiety Lab streamlined to experimental tools only

**Enhancements:**
- Dynamic image support (unlimited gallery images)
- Safe Place landscape mode
- Sleep-friendly colors
- Affirmations color-coding and sizing
- Vault door image support

**All changes maintain:**
- Local storage only (no external databases)
- Privacy-first design
- Backward compatibility

---

**Version:** v2.6  
**Build Date:** January 3, 2026  
**APK:** `AnxietyAnchor-v2.6-FINAL.apk` (81.19 MB)

