# ANXIETY ANCHOR - TESTING GUIDE

## TESTING ENVIRONMENT SETUP

### Prerequisites
- Android device or emulator
- Android Studio (for debugging)
- Java JDK 17+ (for building)

### Java Setup Fix
If you get "JAVA_HOME is set to an invalid directory" error:
1. Download JDK 17 from Oracle or OpenJDK
2. Install to a valid directory (e.g., C:\Program Files\Java\jdk-17)
3. Set JAVA_HOME environment variable
4. Add Java to PATH

---

## MANUAL TESTING CHECKLIST

### 1. PANIC BUTTON TESTING
**Test Cases:**
- [ ] **Basic Functionality**: Tap panic button → opens PanicResponseActivity
- [ ] **Emergency Response**: Verify breathing exercises appear
- [ ] **Navigation**: Back button works correctly
- [ ] **Rapid Tapping**: App doesn't crash with multiple rapid taps
- [ ] **Memory Usage**: No memory leaks during panic response

**Expected Behavior:**
- Smooth transition to panic response screen
- Breathing exercise animations work
- Emergency contact info displays correctly
- No crashes or freezes

### 2. SAFE PLACE TESTING
**Test Cases:**
- [ ] **Visualization Loads**: Safe place image/text displays
- [ ] **Audio Integration**: Calming sounds play correctly
- [ ] **Timer Function**: Countdown timer works
- [ ] **Exit Function**: Can exit safely
- [ ] **Data Persistence**: Settings save between sessions

**Expected Behavior:**
- Calming interface loads quickly
- Audio plays without interruption
- Timer counts down properly
- Exit returns to main screen

### 3. RESCUE CHAT TESTING
**Test Cases:**
- [ ] **Chat Interface**: Messages display correctly
- [ ] **Response Generation**: AI responses appear
- [ ] **Input Handling**: Text input works properly
- [ ] **Send Button**: Messages send without errors
- [ ] **Chat History**: Previous messages persist

**Expected Behavior:**
- Chat interface is responsive
- AI responses are helpful and relevant
- No crashes during chat
- Messages save correctly

### 4. AUDIO LIBRARY TESTING
**Test Cases:**
- [ ] **Audio Playback**: All sounds play correctly
- [ ] **Play/Pause**: Controls work properly
- [ ] **Volume Control**: Volume adjusts correctly
- [ ] **Background Play**: Audio continues when app minimized
- [ ] **Multiple Sounds**: Can switch between different audio files

**Expected Behavior:**
- All audio files play without errors
- Controls are responsive
- No audio glitches or crashes
- Background playback works

### 5. VOICE MEMO TESTING
**Test Cases:**
- [ ] **Recording**: Voice memo recording works
- [ ] **Playback**: Recorded memos play back
- [ ] **Storage**: Memos save correctly
- [ ] **Permissions**: Microphone permission handled
- [ ] **File Management**: Can delete old memos

**Expected Behavior:**
- Recording starts/stops properly
- Playback quality is good
- Files save to device storage
- Permission requests work correctly

### 6. ANXIETY LAB TESTING
**Test Cases:**
- [ ] **Log Creation**: Can create new anxiety logs
- [ ] **Data Entry**: All fields accept input
- [ ] **Save Function**: Logs save correctly
- [ ] **View Logs**: Can view previous entries
- [ ] **Edit Logs**: Can modify existing entries
- [ ] **Delete Logs**: Can remove entries

**Expected Behavior:**
- All form fields work properly
- Data saves without corruption
- Log list displays correctly
- Edit/delete functions work

### 7. MENTAL HEALTH RESOURCES TESTING
**Test Cases:**
- [ ] **Resource List**: All resources display
- [ ] **Link Functionality**: External links work
- [ ] **Search Function**: Can search resources
- [ ] **Categories**: Filtering works correctly
- [ ] **Contact Info**: Phone numbers/emails are correct

**Expected Behavior:**
- Resource list loads quickly
- Links open in browser
- Search returns relevant results
- Contact information is accurate

### 8. PRIVACY & SETTINGS TESTING
**Test Cases:**
- [ ] **Privacy Policy**: Policy displays correctly
- [ ] **Consent Management**: Can accept/decline consent
- [ ] **Data Deletion**: Can clear app data
- [ ] **Settings Persistence**: Settings save correctly
- [ ] **Emergency Contacts**: Contact setup works

**Expected Behavior:**
- Privacy policy is accessible
- Consent flow works properly
- Data clearing functions work
- Settings persist between sessions

---

## STRESS TESTING

### Performance Testing
- [ ] **Long Sessions**: Use app for 30+ minutes
- [ ] **Memory Usage**: Check for memory leaks
- [ ] **Battery Usage**: Monitor battery consumption
- [ ] **Storage Usage**: Check app storage growth
- [ ] **Network Usage**: Monitor data usage

### Crash Testing
- [ ] **Rapid Navigation**: Quickly tap between screens
- [ ] **Large Data**: Create many log entries
- [ ] **Audio Conflicts**: Play multiple audio sources
- [ ] **Permission Denial**: Deny permissions and test
- [ ] **Low Memory**: Test with limited device memory

---

## BUG REPORTING FORMAT

### Bug Report Template
```
**Bug Title**: [Brief description]

**Severity**: [Critical/High/Medium/Low]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior**: [What should happen]

**Actual Behavior**: [What actually happens]

**Device Info**:
- Device: [Phone model]
- Android Version: [Version number]
- App Version: [Version number]

**Screenshots**: [If applicable]

**Additional Notes**: [Any other relevant info]
```

---

## TESTING TOOLS

### Android Studio Debugging
- **Logcat**: Monitor app logs for errors
- **Layout Inspector**: Check UI issues
- **Memory Profiler**: Monitor memory usage
- **Network Profiler**: Check network calls

### Manual Testing Tools
- **Screen Recorder**: Record bug reproduction
- **Screenshot Tool**: Capture visual issues
- **Performance Monitor**: Check CPU/memory usage

---

## COMMON ISSUES TO WATCH FOR

### UI Issues
- Buttons not responding
- Text overflow
- Layout misalignment
- Color contrast problems
- Touch target size issues

### Functional Issues
- Data not saving
- Crashes on specific actions
- Permission handling errors
- Audio playback issues
- Navigation problems

### Performance Issues
- Slow loading times
- Memory leaks
- Battery drain
- Storage bloat
- Network timeouts

---

## TESTING SCHEDULE

### Daily Testing (During Development)
- [ ] Run through core features
- [ ] Check for new bugs
- [ ] Verify fixes work
- [ ] Test on different devices

### Weekly Testing (Comprehensive)
- [ ] Full feature testing
- [ ] Performance testing
- [ ] Stress testing
- [ ] Bug regression testing

### Pre-Release Testing
- [ ] Complete feature testing
- [ ] Performance optimization
- [ ] Security testing
- [ ] User acceptance testing

---

## SUCCESS CRITERIA

### App Stability
- No crashes during normal use
- All features work as intended
- Data persists correctly
- Performance is acceptable

### User Experience
- Intuitive navigation
- Responsive interface
- Helpful error messages
- Smooth animations

### Technical Quality
- Clean code structure
- Proper error handling
- Efficient resource usage
- Security best practices

---

*Last Updated: [Current Date]*
*Testing Guide Version: 1.0*
