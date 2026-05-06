# Voice Feature Implementation Guide

## ✅ **What's Been Added**

### **1. Reusable TTS Helper (`TTSHelper.kt`)**
- Centralized Text-to-Speech functionality
- Optimized for soothing, feminine voice
- Can be used across the app (affirmations, rescue chat, etc.)

### **2. Voice Support in Affirmations**
- **"🔊 Play" button** on each affirmation card
- **"🔊 Play" button** in affirmation dialog
- Automatically speaks the affirmation text when clicked

### **3. Voice Support in Rescue Chat**
- Already implemented with voice toggle switch
- Uses the same TTS system for consistency

---

## 🎯 **How It Works**

### **For Affirmations:**

1. **In the List View:**
   - Each affirmation card has a "🔊 Play" button at the bottom
   - Click it to hear the affirmation spoken

2. **In the Dialog:**
   - When you tap an affirmation, a dialog opens
   - Click "🔊 Play" button to hear it spoken
   - Also has "Copy" button to copy text

### **For Rescue Chat:**

1. **Voice Toggle Switch:**
   - Toggle the voice switch ON to enable automatic speech
   - Messages will be spoken automatically as they appear
   - Toggle OFF to stop speech

---

## 🔧 **Technical Details**

### **TTS Helper Features:**
- **Automatic Voice Selection:** Finds best female voice available
- **Optimized Settings:**
  - Pitch: 1.15-1.2 (more feminine)
  - Speech Rate: 0.85 (natural pace)
- **Google TTS Preferred:** Uses Google TTS if available for better quality
- **Fallback Support:** Works with default TTS if Google TTS unavailable

### **Voice Quality Priority:**
1. Neural/Enhanced/WaveNet female voices (best quality)
2. Google high-quality female voices
3. Named female voices (Samantha, Susan, Karen, etc.)
4. Any female voice
5. Default English voice (fallback)

---

## 📝 **How to Use in Other Activities**

If you want to add voice to other parts of the app:

```kotlin
// 1. Create TTSHelper instance
private var ttsHelper: TTSHelper? = null

// 2. Initialize in onCreate
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // ... other setup ...
    
    ttsHelper = TTSHelper(this)
    ttsHelper?.initialize { success ->
        if (success) {
            ttsHelper?.setVoiceEnabled(true)
        }
    }
}

// 3. Speak text
fun speakText(text: String) {
    if (ttsHelper?.isReady() == true) {
        ttsHelper?.speak(text)
    }
}

// 4. Cleanup in lifecycle
override fun onDestroy() {
    super.onDestroy()
    ttsHelper?.shutdown()
}

override fun onPause() {
    super.onPause()
    ttsHelper?.pause()
}
```

---

## 🎨 **UI Elements Added**

### **Affirmation Card:**
- Added "🔊 Play" button at bottom of each card
- Button is styled as Material TextButton
- Positioned at the end (right side)

### **Affirmation Dialog:**
- Added "🔊 Play" button (negative button)
- "Copy" button (neutral button)
- "Close" button (positive button)

---

## ⚙️ **Configuration**

### **Voice Settings (in TTSHelper.kt):**
- **Pitch:** 1.15-1.2 (adjustable, range 0.0-2.0)
- **Speech Rate:** 0.85 (adjustable, range 0.0-2.0)
- **Audio Stream:** STREAM_MUSIC (for better quality)

### **To Adjust Voice:**
Edit `TTSHelper.kt`:
```kotlin
textToSpeech?.setPitch(1.2f)  // Higher = more feminine
textToSpeech?.setSpeechRate(0.85f)  // Lower = slower
```

---

## 🐛 **Troubleshooting**

### **Voice Not Working?**
1. Check if TTS is initialized: `ttsHelper?.isReady()`
2. Check if voice is enabled: `ttsHelper?.isVoiceEnabled()`
3. Check device TTS settings (Settings > Accessibility > Text-to-Speech)
4. Ensure Google TTS is installed (for best quality)

### **Voice Sounds Robotic?**
- Device may not have Google TTS installed
- Install Google Text-to-Speech from Play Store
- App will automatically use it if available

---

## 📱 **User Experience**

### **Affirmations:**
- Users can **read** affirmations (color-coded, large text)
- Users can **listen** to affirmations (click 🔊 Play)
- Users can **copy** affirmations (click Copy in dialog)

### **Rescue Chat:**
- Users can **read** messages (displayed in chat bubbles)
- Users can **listen** to messages (toggle voice switch ON)
- Messages spoken automatically as they appear

---

## 🚀 **Future Enhancements**

Potential improvements:
- Voice speed control (slower/faster)
- Voice selection (choose different voices)
- Auto-play option for affirmations
- Background playback support
- Voice volume control

---

## ✅ **Summary**

**Voice feature is now fully implemented!**

- ✅ Affirmations have voice support (Play button)
- ✅ Rescue Chat has voice support (toggle switch)
- ✅ Reusable TTSHelper for future features
- ✅ Optimized for soothing, feminine voice
- ✅ Automatic cleanup on activity destroy/pause

**Users can now:**
- Listen to affirmations instead of just reading
- Have rescue chat messages spoken automatically
- Enjoy consistent, high-quality voice across the app

