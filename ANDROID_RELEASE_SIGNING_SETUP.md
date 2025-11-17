# Android Release Signing Setup Guide

This guide explains how to configure proper release signing for the SortBliss Android app.

## Why This Is Required

Google Play Store requires all apps to be signed with a unique certificate. Using debug signing (the default) will cause Play Store to reject your upload.

## Step-by-Step Instructions

### 1. Generate a Release Keystore

Open a terminal and run the following command:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You will be prompted for:**
- **Keystore password:** Choose a strong password (save this securely!)
- **Key password:** Choose a strong password (can be same as keystore password)
- **Your name, organization, city, state, country:** Fill in your information

**Important:** The keystore file will be created in your current directory. Move it to `/home/user/sortbliss/android/upload-keystore.jks`

```bash
mv upload-keystore.jks /home/user/sortbliss/android/
```

### 2. Create keystore.properties File

Copy the example template:

```bash
cd /home/user/sortbliss/android
cp keystore.properties.example keystore.properties
```

Edit `keystore.properties` with your actual values:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with the keystore password you created
- `YOUR_KEY_PASSWORD` with the key password you created

### 3. Secure Your Keystore

**CRITICAL:** Never commit your keystore or keystore.properties to version control!

Verify `.gitignore` contains:

```
# Android signing
android/keystore.properties
android/*.jks
android/*.keystore
```

### 4. Test Release Build

Build a signed release APK:

```bash
flutter build apk --release
```

Or build an App Bundle (recommended for Play Store):

```bash
flutter build appbundle --release
```

If successful, your signed build will be at:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### 5. Backup Your Keystore

**EXTREMELY IMPORTANT:**

1. **Copy `upload-keystore.jks` to a secure location** (USB drive, password manager, encrypted cloud storage)
2. **Save your passwords** in a password manager
3. **If you lose this keystore, you cannot update your app in Play Store!**

## Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app or select existing app
3. Navigate to "Release" > "Production"
4. Click "Create new release"
5. Upload `app-release.aab` (App Bundle is recommended over APK)
6. Fill in release notes and submit for review

## Troubleshooting

### Error: "keystore.properties not found"

Solution: Create the file following Step 2 above. The build will fall back to debug signing if the file doesn't exist.

### Error: "Keystore was tampered with, or password was incorrect"

Solution: Double-check passwords in `keystore.properties` match what you used when creating the keystore.

### Error: "Key with alias 'upload' does not exist"

Solution: Verify the `keyAlias` in `keystore.properties` matches the alias you used in the `keytool` command (default is "upload").

## Security Best Practices

1. ✅ Never commit keystore files to Git
2. ✅ Never share keystore passwords publicly
3. ✅ Back up keystore in multiple secure locations
4. ✅ Use strong, unique passwords (minimum 12 characters)
5. ✅ Consider using Google Play App Signing (Play Console handles key management)

## Google Play App Signing (Recommended)

For maximum security, enable Google Play App Signing:

1. In Play Console, go to "Setup" > "App signing"
2. Follow instructions to upload your upload certificate
3. Google will manage the final signing key
4. You keep the upload key for releasing updates

Benefits:
- Google protects your app signing key
- You can reset upload key if compromised
- Simplified key management

---

**Next Steps:** After configuring signing, proceed with creating your first production release!
