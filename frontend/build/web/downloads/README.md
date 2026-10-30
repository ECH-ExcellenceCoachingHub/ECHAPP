# Excellence Coaching Hub Downloads

## How to Build the App for Distribution

This directory contains the downloadable versions of the Excellence Coaching Hub app for Android and iOS platforms.

### Prerequisites

Before building the app, make sure you have:

1. **Flutter SDK** (3.0.0 or higher)
2. **Android Studio** or **VS Code** with Flutter extensions
3. **Android SDK** for Android builds
4. **Xcode** for iOS builds (macOS only)
5. **Git** for cloning the repository

### Cloning the Repository

```bash
# Clone the repository
git clone https://github.com/your-organization/excellence-coaching-hub.git

# Navigate to the frontend directory
cd excellence-coaching-hub/frontend
```

### Building for Android

To build the Android APK for distribution:

```bash
# Get dependencies
flutter pub get

# Generate code (for Freezed models)
flutter pub run build_runner build

# Build the release APK
flutter build apk --release

# The APK file will be located at:
# build/app/outputs/flutter-apk/app-release.apk

# For a universal APK
flutter build apk --split-per-abi --release
```

### Building for iOS

To build the iOS IPA for distribution:

```bash
# Get dependencies
flutter pub get

# Generate code (for Freezed models)
flutter pub run build_runner build

# Open iOS project in Xcode (macOS only)
cd ios && open Runner.xcworkspace

# In Xcode:
# 1. Select your development team in Project Settings
# 2. Update bundle identifier
# 3. Build the release IPA
flutter build ios --release

# The IPA file will be located in:
# build/ios/ipa/

# For simulator builds (for testing):
flutter build ios --simulator --debug
```

### Alternative: Web Version

You can also build and deploy the web version:

```bash
# Get dependencies
flutter pub get

# Build for web
flutter build web --release

# The web app will be available in build/web/
# Serve locally for testing:
flutter run -d chrome --release
```

### Desktop Builds

The app also supports desktop platforms:

```bash
# For Windows
flutter build windows --release

# For macOS
flutter build macos --release

# For Linux
flutter build linux --release
```

### Configuration

Make sure to set up your environment variables before building:

1. Create a `.env` file in the frontend directory
2. Add the API base URL:

```env
API_BASE_URL=https://your-backend-api.com/api
```

### Distribution Options

1. **App Stores**: Submit to Google Play Store and Apple App Store for public distribution
2. **Enterprise**: Distribute IPA files directly for enterprise deployment
3. **APK Distribution**: Share APK files for direct installation on Android
4. **Web App**: Host the web build for browser access

---

**Note**: The actual APK and IPA files are not included in this repository due to their size. They need to be built using the Flutter CLI as described above.