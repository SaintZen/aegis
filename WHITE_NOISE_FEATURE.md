# White Noise Feature - Affirmations Library

## 🔊 **Optional White Noise Background**

The Affirmations Library now includes an **optional white noise toggle** to help users focus while reading or listening to affirmations.

---

## ✅ **What's Been Implemented**

### **1. White Noise Toggle**
- **Location:** Top of Affirmations Library screen
- **Control:** Material Switch (on/off)
- **Description:** "Subtle background sound to help focus while reading or listening"

### **2. Smart Volume Control**
- **Volume Level:** Automatically set to 30% of max volume
- **Purpose:** Ensures white noise doesn't interfere with TTS (Text-to-Speech)
- **User Control:** Users can still adjust device volume if needed

### **3. Automatic Cleanup**
- **On Activity Exit:** White noise automatically stops when leaving the screen
- **Resource Management:** Prevents audio from playing in background unnecessarily

---

## 🔬 **Research-Backed Benefits**

### **Why White Noise Helps:**

1. **Focus Enhancement:**
   - Masks distracting background sounds
   - Creates consistent auditory backdrop
   - Helps maintain attention during reading/listening

2. **Cognitive Performance:**
   - Studies show improved new word learning with white noise
   - Particularly beneficial for individuals with attention difficulties
   - Can improve concentration during cognitive tasks

3. **Relaxation:**
   - Consistent sound can be calming
   - Reduces environmental distractions
   - Creates a "cocoon" effect for focus

### **Important Notes:**
- **Individual Variation:** White noise effects vary by person
- **Optional:** Users can toggle it on/off based on preference
- **Low Volume:** Set to 30% to avoid interfering with TTS clarity

---

## 🎨 **User Experience**

### **How It Works:**

1. **User opens Affirmations Library**
2. **Sees white noise toggle at top of screen**
3. **Toggles switch ON** → Subtle ambient sound starts playing
4. **Reads or listens to affirmations** with background sound
5. **Toggles switch OFF** → Sound stops immediately
6. **Leaves screen** → Sound automatically stops

### **Visual Design:**
- Clean Material Design card
- Clear label: "🔊 White Noise"
- Helpful description text
- Easy-to-use switch control

---

## ⚙️ **Technical Implementation**

### **Audio Source:**
- Uses existing `calming_3` audio file (soft ambient tones)
- Loops continuously while enabled
- Managed by `AudioService` class

### **Volume Control:**
```kotlin
val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
val targetVolume = (maxVolume * 0.3).toInt()  // 30% volume
audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
```

### **Lifecycle Management:**
- **onCreate:** Initializes white noise track
- **onDestroy:** Stops white noise when activity closes
- **onPause:** (Optional) Can pause when app backgrounds

---

## 💡 **Benefits for Users**

### **Reading Affirmations:**
- ✅ Better focus on text
- ✅ Reduced environmental distractions
- ✅ Enhanced comprehension

### **Listening to Affirmations (TTS):**
- ✅ Background sound doesn't interfere (low volume)
- ✅ Creates immersive experience
- ✅ Helps maintain attention

### **Flexibility:**
- ✅ Optional - users choose what works for them
- ✅ Easy toggle on/off
- ✅ No permanent settings needed

---

## 🎯 **Best Practices**

### **When to Use White Noise:**
- Reading affirmations in noisy environments
- Need help focusing on text
- Want immersive experience
- Prefer background sound for relaxation

### **When to Turn It Off:**
- Prefer silence for reading
- Find background sound distracting
- In quiet environment already
- Listening to TTS and want maximum clarity

---

## 📝 **Summary**

**The Affirmations Library now includes:**
- ✅ Optional white noise toggle
- ✅ Smart volume control (30% max)
- ✅ Automatic cleanup on exit
- ✅ Research-backed focus enhancement
- ✅ User-friendly Material Design UI

**This feature:**
- Helps users focus while reading/listening
- Reduces environmental distractions
- Enhances the affirmation experience
- Gives users control over their environment

**The white noise is:**
- Optional (user choice)
- Low volume (doesn't interfere with TTS)
- Easy to toggle on/off
- Automatically stops when leaving screen

---

**The Affirmations Library is now more immersive and focused! 🔊**

