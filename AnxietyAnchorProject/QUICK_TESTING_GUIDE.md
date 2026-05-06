# QUICK TESTING GUIDE - ANXIETY ANCHOR

## IMMEDIATE TESTING (No Build Required)

### 1. MANUAL FEATURE TESTING
**Test each feature systematically:**

**Panic Button:**
- [ ] Tap panic button
- [ ] Verify breathing exercises appear
- [ ] Test back navigation
- [ ] Check emergency contact display

**Safe Place:**
- [ ] Open safe place feature
- [ ] Test audio playback
- [ ] Verify timer functionality
- [ ] Test exit button

**Rescue Chat:**
- [ ] Open chat interface
- [ ] Type a message and send
- [ ] Verify AI response appears
- [ ] Test multiple messages

**Audio Library:**
- [ ] Open audio library
- [ ] Play different calming sounds
- [ ] Test play/pause controls
- [ ] Check volume adjustment

**Voice Memos:**
- [ ] Test recording functionality
- [ ] Play back recorded memo
- [ ] Check file saving
- [ ] Test delete function

**Anxiety Lab:**
- [ ] Create new log entry
- [ ] Fill out all form fields
- [ ] Save the entry
- [ ] View saved entries
- [ ] Edit an existing entry

**Mental Health Resources:**
- [ ] Browse resource list
- [ ] Test search function
- [ ] Click on external links
- [ ] Verify contact information

**Settings & Privacy:**
- [ ] Access privacy policy
- [ ] Test emergency contact setup
- [ ] Check data clearing options
- [ ] Verify settings persistence

### 2. CRASH TESTING
**Try to break the app:**

- [ ] **Rapid Button Pressing**: Tap buttons very quickly
- [ ] **Multiple Features**: Open multiple features simultaneously
- [ ] **Long Sessions**: Use app for 15+ minutes continuously
- [ ] **Data Entry**: Enter very long text in all fields
- [ ] **Audio Conflicts**: Play multiple audio sources
- [ ] **Navigation**: Rapidly switch between screens

### 3. PERMISSION TESTING
**Test permission handling:**

- [ ] **Deny Microphone**: Try voice memos without permission
- [ ] **Deny Storage**: Try saving without permission
- [ ] **Grant Permissions**: Test after granting permissions
- [ ] **Revoke Permissions**: Test after revoking permissions

### 4. DATA PERSISTENCE TESTING
**Test data saving:**

- [ ] **Create Data**: Add emergency contacts, logs, memos
- [ ] **Close App**: Force close the app completely
- [ ] **Reopen App**: Check if data is still there
- [ ] **Restart Device**: Test data persistence after restart

### 5. UI/UX TESTING
**Check interface issues:**

- [ ] **Text Overflow**: Look for text that doesn't fit
- [ ] **Button Responsiveness**: Check if all buttons work
- [ ] **Screen Orientation**: Test in portrait and landscape
- [ ] **Color Contrast**: Check if text is readable
- [ ] **Touch Targets**: Verify buttons are easy to tap

## BUG REPORTING

### When You Find a Bug:
1. **Note the exact steps** to reproduce
2. **Describe what should happen**
3. **Describe what actually happens**
4. **Take a screenshot** if possible
5. **Note your device** and Android version

### Example Bug Report:
```
**Bug**: Panic button doesn't respond to rapid tapping

**Steps to Reproduce**:
1. Open AnxietyAnchor app
2. Tap panic button 10 times quickly
3. App freezes/crashes

**Expected**: App should handle rapid tapping gracefully
**Actual**: App freezes and needs restart

**Device**: Samsung Galaxy S21, Android 12
```

## COMMON ISSUES TO LOOK FOR

### Critical Issues:
- App crashes on startup
- Panic button doesn't work
- Audio doesn't play
- Data doesn't save
- Can't exit features

### Medium Issues:
- Slow response times
- UI elements misaligned
- Text hard to read
- Buttons feel unresponsive
- Audio glitches

### Minor Issues:
- Spelling errors
- Color preferences
- Animation smoothness
- Loading times
- Visual polish

## TESTING PRIORITY

### High Priority (Test First):
1. Panic button functionality
2. Emergency contact setup
3. Audio playback
4. Data saving
5. App stability

### Medium Priority:
1. All navigation buttons
2. Form input fields
3. Search functions
4. External links
5. Settings persistence

### Low Priority:
1. Visual polish
2. Animation smoothness
3. Loading times
4. Minor UI adjustments
5. Performance optimization

## SUCCESS CRITERIA

### App is Ready When:
- [ ] No crashes during normal use
- [ ] All core features work
- [ ] Data saves correctly
- [ ] Audio plays properly
- [ ] Navigation is smooth
- [ ] Emergency features are reliable

### Ready for iOS Development When:
- [ ] All bugs are documented
- [ ] Critical issues are fixed
- [ ] User experience is smooth
- [ ] Feature set is finalized
- [ ] Testing is complete

---

**Start Testing Now!** 
Go through each feature systematically and note any issues you find.
