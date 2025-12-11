# Build & Deployment Guide

## Konfiguration abgeschlossen ✅

### Android
- **Application ID:** `com.alexandermessinger.corejourney`
- **Version:** 1.0.0 (Build 1)
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** Latest
- **ProGuard:** Aktiviert für Release
- **Signing:** Konfiguriert (Keystore erforderlich)

### iOS
- **Bundle ID:** `com.alexandermessinger.corejourney`
- **Version:** 1.0.0 (Build 1)
- **Min iOS:** 13.0
- **Display Name:** CoreJourney

---

## Release Build erstellen

### Android (.aab für Play Store)

```bash
# 1. Keystore erstellen (nur einmal)
keytool -genkey -v -keystore ~/corejourney-release.keystore \
  -alias corejourney -keyalg RSA -keysize 2048 -validity 10000

# 2. key.properties erstellen (siehe android/SIGNING_SETUP.md)

# 3. Release Build
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (.ipa für App Store)

```bash
# 1. Xcode öffnen
open ios/Runner.xcworkspace

# 2. Signing & Capabilities → Team auswählen
# 3. Build für "Any iOS Device (arm64)"

# Oder via CLI:
flutter build ipa --release

# Output: build/ios/ipa/corejourney.ipa
```

---

## Test Builds (Debug)

### Android
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### iOS (Simulator)
```bash
flutter build ios --simulator
```

---

## Vor der Submission

### Checkliste
- [ ] App Icons erstellt (Android & iOS)
- [ ] Launch Screens erstellt
- [ ] Screenshots für Store erstellt
- [ ] Privacy Policy URL vorhanden
- [ ] App Beschreibung (DE & EN)
- [ ] Alle Features getestet

### Signing
- [ ] Android: Keystore erstellt & gesichert
- [ ] Android: key.properties konfiguriert
- [ ] iOS: Apple Developer Account
- [ ] iOS: Distribution Certificate
- [ ] iOS: Provisioning Profile

---

## Store Submission

### Google Play Console
1. Release erstellen
2. AAB hochladen (`app-release.aab`)
3. Store Listing ausfüllen
4. Content Rating
5. Review & Release

### Apple App Store Connect
1. App erstellen
2. IPA hochladen (via Xcode oder Transporter)
3. App Information
4. Screenshots
5. Submit for Review

---

## Build-Befehle Übersicht

```bash
# Android Debug
flutter run

# Android Release Build
flutter build appbundle --release

# iOS Debug (Simulator)
flutter run

# iOS Release Build
flutter build ipa --release

# Beide Plattformen testen
flutter build apk --debug
flutter build ios --debug

# Build analysieren
flutter build appbundle --release --analyze-size
```

---

## Troubleshooting

### Android: Keystore Fehler
```bash
# Keystore Pfad prüfen
cat android/key.properties

# Build ohne Signing (für Test)
flutter build apk --debug
```

### iOS: Signing Fehler
- Xcode öffnen: `open ios/Runner.xcworkspace`
- Signing & Capabilities → Automatisch verwalten
- Team auswählen

---

## Nächste Schritte

1. ✅ Build Config abgeschlossen
2. 🎨 App Icons erstellen (512x512, 1024x1024)
3. 📸 Screenshots erstellen
4. 📝 Store Listings vorbereiten
5. 🔐 Signing einrichten
6. 🎯 Test Builds erstellen
7. 🚀 Store Submission

---

## Wichtige Dateien

- **Android:**
  - `android/app/build.gradle.kts` - Build Config
  - `android/app/proguard-rules.pro` - ProGuard Rules
  - `android/key.properties` - Signing (nicht in Git!)
  - `android/SIGNING_SETUP.md` - Signing Anleitung

- **iOS:**
  - `ios/Runner.xcodeproj/project.pbxproj` - Xcode Project
  - `ios/Runner/Info.plist` - App Info

- **Allgemein:**
  - `pubspec.yaml` - Version & Dependencies
