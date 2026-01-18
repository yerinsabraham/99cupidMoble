# 99cupid Mobile - Android Setup Guide

## Prerequisites

1. **Flutter SDK** (3.10.1 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Android Studio**
   - Download from: https://developer.android.com/studio
   - Install Android SDK and Android SDK Command-line tools

3. **Java JDK** (11 or higher)
   - Download from: https://www.oracle.com/java/technologies/downloads/

## Setup Steps

### 1. Clone Repository
```bash
git clone https://github.com/yerinsabraham/99cupidMoble.git
cd 99cupidMoble
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration (Already Configured)
The app is already configured with Firebase for Android:
- `android/app/google-services.json` - Firebase config file
- Package name: `com.cupid99.cupid_99`

### 4. Android SDK Setup
Make sure you have the following installed via Android Studio SDK Manager:
- Android SDK Platform 33 (Android 13)
- Android SDK Build-Tools
- Android Emulator (optional, for testing)

### 5. Connect Device or Start Emulator

**Physical Device:**
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices` to verify

**Emulator:**
1. Open Android Studio > Device Manager
2. Create a new Virtual Device (Pixel 5 or similar recommended)
3. Start the emulator

### 6. Run the App
```bash
flutter run
```

Or for release build:
```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### Gradle Build Errors
If you get Gradle errors, try:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Google Sign-In Issues
Make sure:
1. SHA-1 fingerprint is added to Firebase console
2. Download latest `google-services.json` from Firebase console
3. Place it in `android/app/` directory

To get SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```

### Permission Errors
The app requires:
- Internet access (already configured in AndroidManifest.xml)
- Camera (for photo uploads)
- Storage (for selecting photos)

All permissions are handled at runtime.

## Building for Release

1. **Generate Keystore** (first time only):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Create `android/key.properties`**:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-your-keystore>
```

3. **Build Release APK**:
```bash
flutter build apk --release
```

4. **Build App Bundle** (for Google Play):
```bash
flutter build appbundle --release
```

## Firebase Project

- Project ID: `cupid-e5874`
- Web API Key: Already configured in app
- All Firestore rules deployed and working

## Support

For issues, contact: yerinssaibs@gmail.com
