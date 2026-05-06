# Guide: Adding More Images and Pink/White Noise

## 📸 **Adding More Gallery Images**

### **How It Works:**
The app now **dynamically detects** gallery images - you can add as many as you want!

### **Steps to Add Images:**

1. **Add image files to:** `AnxietyAnchor/app/src/main/res/drawable/`
2. **Name them:** `gallery_1.png`, `gallery_2.png`, `gallery_3.png`, etc.
   - Numbers must be sequential (1, 2, 3, 4, 5...)
   - Supported formats: `.png`, `.jpg`, `.webp`
3. **The app will automatically:**
   - Detect all available images
   - Display them in Safe Place gallery
   - Show them in Calming Gallery
   - Make them available for Frosted Glass Grounding

### **Current Images:**
- `gallery_1.png`
- `gallery_2.png`
- `gallery_3.png`
- `gallery_4.png`

### **To Add More:**
Simply add `gallery_5.png`, `gallery_6.png`, `gallery_7.png`, etc. to the `drawable` folder.

**Note:** The app checks up to 20 images automatically. If you need more, the code can be easily adjusted.

---

## 🔊 **Adding Pink and White Noise**

### **How It Works:**
The app now supports **both Pink Noise and White Noise** with a toggle selector!

### **Steps to Add Noise Files:**

1. **Add audio files to:** `AnxietyAnchor/app/src/main/res/raw/`
2. **Name them:**
   - `white_noise.mp3` - For white noise
   - `pink_noise.mp3` - For pink noise
3. **The app will automatically:**
   - Detect the noise files
   - Show White/Pink toggle buttons in Affirmations Library
   - Play the selected noise type
   - Fall back to ambient sounds if noise files don't exist

### **Current Audio Files:**
- `calming_1.mp3` (Shoreline waves)
- `calming_2.mp3` (Forest ambiance)
- `calming_3.mp3` (Soft ambient tones)
- `calming_4.mp3` (Deep ambient pad)

### **To Add Noise Files:**
1. Get or generate white noise and pink noise audio files
2. Name them: `white_noise.mp3` and `pink_noise.mp3`
3. Place them in `AnxietyAnchor/app/src/main/res/raw/`
4. The app will automatically use them when selected!

### **Fallback Behavior:**
If `white_noise.mp3` or `pink_noise.mp3` don't exist, the app will:
- Try to find the selected noise type
- Fall back to ambient sounds (`calming_1`, `calming_2`, etc.)
- Show a message if no audio is available

---

## 🎨 **Where Images Are Used**

### **1. Safe Place Activity**
- Main display image
- Thumbnail strip for selection
- Full-screen landscape mode

### **2. Calming Gallery**
- Grid display of all images
- Browse all available calming images

### **3. Frosted Glass Grounding**
- Background images for the grounding exercise
- Users rub to reveal the hidden image

---

## 🔊 **Where Noise Is Used**

### **Affirmations Library**
- Background noise toggle (White/Pink selector)
- Helps focus while reading or listening to affirmations
- Set to 30% volume to avoid interfering with TTS

---

## 📝 **Technical Details**

### **Image Detection:**
- Checks images sequentially: `gallery_1`, `gallery_2`, `gallery_3`...
- Stops when it finds a gap of 3+ missing images after finding some
- Maximum check: 20 images (can be increased if needed)

### **Noise Selection:**
1. First priority: `white_noise.mp3` or `pink_noise.mp3`
2. Fallback: Ambient sounds (`calming_1`, `calming_2`, etc.)
3. User can toggle between White and Pink noise
4. Volume set to 30% for background focus

---

## ✅ **Quick Summary**

### **To Add More Images:**
1. Add `gallery_5.png`, `gallery_6.png`, etc. to `res/drawable/`
2. They'll automatically appear in Safe Place and Gallery!

### **To Add Pink/White Noise:**
1. Add `white_noise.mp3` and `pink_noise.mp3` to `res/raw/`
2. They'll automatically be available in Affirmations Library!

---

**That's it! The app handles everything automatically.** 🎉

