# Sleep-Friendly Features - Blue Light Reduction

## 🌙 **Sleep Hours: 6pm - 6am**

The app now automatically uses **warmer, sleep-friendly colors** during evening and night hours (6pm-6am) to reduce blue light exposure that can interfere with sleep.

---

## ✅ **What's Been Implemented**

### **1. Breathing Circle - Time-Based Colors**

**Daytime (6am - 6pm):**
- INHALE: Blue (calm_blue)
- HOLD IN: Green (calm_green)
- EXHALE: Purple (calm_purple)
- HOLD OUT: Warm Amber (warm_amber)

**Sleep Hours (6pm - 6am):**
- INHALE: Soft Lavender (soft_lavender) - **No blue light**
- HOLD IN: Warm Amber (warm_amber) - **Warm, soothing**
- EXHALE: Soft Lavender (soft_lavender) - **No blue light**
- HOLD OUT: Warm Amber (warm_amber) - **Warm, grounding**

**Why This Matters:**
- Blue light suppresses melatonin production
- Warmer colors (amber, lavender) don't interfere with sleep
- Automatic switching based on time of day

---

### **2. Dark Mode - Sleep-Friendly Colors**

**Dark Mode Colors (Reduced Blue Light):**
- Primary buttons: Purple instead of blue
- Calm colors: Purple/lavender instead of blue
- Ripple effects: Soft lavender instead of blue
- All blue elements replaced with warmer alternatives

**Why This Matters:**
- Dark mode is often used at night
- Warmer colors reduce blue light exposure
- Better for sleep hygiene

---

## 🔬 **Science Behind It**

### **Blue Light and Sleep:**
- Blue light (especially 460-480nm) suppresses melatonin
- Melatonin is essential for sleep
- Exposure to blue light before bed can delay sleep onset
- Warmer colors (red, amber, orange) have less impact on melatonin

### **Research-Backed:**
- Studies show blue light exposure 2-3 hours before bed can delay sleep by 1-2 hours
- Warmer colors (red/amber spectrum) have minimal impact on circadian rhythm
- Many sleep apps now use "night mode" with warmer colors

---

## 🎨 **Color Changes**

### **Breathing Circle:**
- **Daytime:** Blue, Green, Purple, Amber (normal colors)
- **Sleep Hours:** Lavender, Amber, Lavender, Amber (warm colors, no blue)

### **Dark Mode:**
- **Primary Color:** Purple (#BA68C8) instead of Blue (#64B5F6)
- **Calm Blue:** Purple (#BA68C8) instead of Blue
- **Ripple Effects:** Soft Lavender instead of Blue

---

## ⚙️ **How It Works**

### **Automatic Time Detection:**
- App checks current time when breathing exercise starts
- If time is between 6pm-6am, uses warm colors
- If time is between 6am-6pm, uses normal colors
- No user configuration needed - automatic!

### **Dark Mode:**
- When device is in dark mode, app uses warmer colors
- Purple/lavender instead of blue throughout
- Reduces blue light exposure automatically

---

## 📱 **User Experience**

### **During Day (6am-6pm):**
- Normal colors (blue, green, purple)
- Full color spectrum available
- No restrictions

### **During Sleep Hours (6pm-6am):**
- Warm colors only (lavender, amber)
- No blue light exposure
- Better for sleep preparation

### **Dark Mode:**
- Always uses warmer colors
- Purple/lavender instead of blue
- Sleep-friendly by default

---

## 💡 **Benefits**

1. **Better Sleep:** Reduced blue light = better melatonin production
2. **Automatic:** No user configuration needed
3. **Science-Backed:** Based on circadian rhythm research
4. **Non-Intrusive:** Colors still beautiful and calming
5. **Health-Focused:** Supports natural sleep patterns

---

## 🎯 **Summary**

**The app now automatically:**
- ✅ Uses warm colors (lavender, amber) during 6pm-6am
- ✅ Reduces blue light exposure during sleep hours
- ✅ Uses warmer colors in dark mode
- ✅ Supports natural sleep patterns
- ✅ No user action required - automatic!

**This helps users:**
- Fall asleep faster
- Maintain natural circadian rhythm
- Reduce blue light exposure before bed
- Use the app safely during evening/night hours

---

## 📝 **Technical Details**

### **Time Detection:**
```kotlin
private fun isSleepHours(): Boolean {
    val calendar = Calendar.getInstance()
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    return hour >= 18 || hour < 6 // 6pm (18:00) to 6am (06:00)
}
```

### **Color Selection:**
- Checks time when `setPhaseColor()` is called
- Automatically selects warm or normal colors
- No performance impact (simple time check)

---

**The app is now sleep-friendly! 🌙**

