# PHUD BOX Flutter App - Setup Summary

## Project Overview
- **Name**: phud_box
- **Type**: Flutter app + Raspberry Pi BLE peripheral
- **Location**: `C:\Users\Kian\Desktop\vscode-projects\phud_box_application\phud_box_flutter\phud_box_flutter\`
- **Target**: Android emulator (API 37, Android 17)

## Current Issues Blocking the Build

### 1. Java Version Too Old
- **Current**: Java 8 (1.8.0_351)
- **Required**: Java 17 or higher
- **Status**: MUST be fixed before Android build works
- **Solution**: Install JDK 17 via `winget install EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements`

### 2. Android SDK Version Mismatch
- **Current**: Project set to `compileSdk = 34`
- **Required**: `compileSdk = 37` (plugins require Android SDK 36/37)
- **Plugins requiring higher SDK**:
  - `flutter_blue_plus_android` requires SDK 36
  - `permission_handler_android` requires SDK 37
- **Status**: Code change needed in `android/app/build.gradle.kts`
- **Solution**: Update `compileSdk = 37` in the android Gradle file

### 3. Android Platform SDKs Missing
- **Missing**: Android SDK Platform 36 and 37
- **Status**: Must be installed via Android SDK Manager
- **Solution**: Use Android Studio SDK Manager or run sdkmanager command to install platforms;android-36 and platforms;android-37

### 4. Android NDK Corrupted
- **Status**: Already cleaned up, will auto-redownload
- **Path**: `C:\Users\Kian\AppData\Local\Android\Sdk\ndk\28.2.13676358`

## Code Changes Required

### File: `android/app/build.gradle.kts`
**Change these lines:**

```kotlin
// BEFORE (current):
android {
    namespace = "com.example.phud_box"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.phud_box"
        minSdk = 21
        targetSdk = 34
        compileSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

// TO THIS (required):
android {
    namespace = "com.example.phud_box"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.phud_box"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
```

### File: `android/app/src/main/AndroidManifest.xml`
**Verify these lines exist (should already be present):**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
        android:usesPermissionFlags="neverForLocation"
        tools:targetApi="s" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />

    <application ...>
```

## Environment Setup Steps (For User)

### Step 1: Install Java 17
```powershell
winget install EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements
```

### Step 2: Set Java 17 as Active
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

Verify output shows Java 17.x, not Java 8.

### Step 3: Install Android SDK Platforms 36 & 37
Open Android Studio → Tools → SDK Manager → SDK Platforms tab
- Check "Android SDK Platform 36"
- Check "Android SDK Platform 37"
- Click "Apply" and wait for installation

OR use command line:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "platforms;android-36" "platforms;android-37"
```

### Step 4: Apply Code Changes
- Update `android/app/build.gradle.kts` with the changes above
- Verify `android/app/src/main/AndroidManifest.xml` has the BLE permissions

### Step 5: Build and Run
```powershell
cd "C:\Users\Kian\Desktop\vscode-projects\phud_box_application\phud_box_flutter\phud_box_flutter"
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## Expected Result

The app should:
1. Compile successfully for Android
2. Launch on the running Android emulator
3. Show the scan screen (Bluetooth may not work in emulator, but app UI should be visible)

## Important Notes

- **BLE in Emulator**: Bluetooth Low Energy does not work reliably in the Android emulator. The app will open, but BLE scanning/connection will fail.
- **Physical Device**: For actual PHUD BOX testing, use a real Android phone with Bluetooth support.
- **Windows Desktop**: The Windows build path still has issues (NuGet/C++ plugin incompatibility). Android is the working target for now.
