# Android App Signing Setup

## Keystore erstellen

### Schritt 1: Keystore generieren

```bash
cd ~/
keytool -genkey -v -keystore corejourney-release.keystore \
  -alias corejourney -keyalg RSA -keysize 2048 -validity 10000
```

**Fragen beantworten:**
- Passwort: [SICHER WÄHLEN]
- Name: Alexander Messinger
- Organisation: CoreJourney
- Stadt: [Deine Stadt]
- Land: DE

> **WICHTIG:** Keystore & Passwort sicher aufbewahren (1Password, etc.)!

### Schritt 2: key.properties erstellen

Erstelle `/Users/alexandermessinger/dev/corejourney/android/key.properties`:

```properties
storePassword=<DEIN_STORE_PASSWORT>
keyPassword=<DEIN_KEY_PASSWORT>
keyAlias=corejourney
storeFile=/Users/alexandermessinger/corejourney-release.keystore
```

### Schritt 3: Zu .gitignore hinzufügen

Die Datei `android/key.properties` ist bereits in `.gitignore`:
```
**/android/key.properties
```

---

## Release Build testen

Nach Keystore-Erstellung:

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Keystore Backup

**KRITISCH:** Keystore mehrfach sichern!
- ☁️ Cloud Storage (verschlüsselt)
- 💾 Externe Festplatte
- 🔐 Password Manager

**Hinweis:** Verlust des Keystores = neue App erstellen müssen!
