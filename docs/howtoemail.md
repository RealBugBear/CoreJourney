# CoreJourney — Email & Deep Link Setup

Dieses Dokument beschreibt vollständig wie Password-Reset-Emails, Universal Links, Custom URL Schemes und Custom SMTP für CoreJourney aufgesetzt wurden.

---

## Übersicht: Was passiert wenn ein User sein Passwort zurücksetzt?

```
1. User tippt "Passwort vergessen" in der App
2. App ruft Supabase auf → Supabase schickt Reset-Email
3. User klickt Link in Email → Browser öffnet Supabase-Verify-URL
4. Supabase verifiziert Token → redirectet zu corejourney://auth/reset-password#access_token=...
5. iOS/Android erkennt corejourney:// → öffnet die App
6. App empfängt Deep Link → setzt Supabase-Session
7. GoRouter redirectet automatisch zu ResetPasswordScreen
8. User setzt neues Passwort
```

---

## Teil 1: Supabase Konfiguration

**URL:** https://supabase.com → Dashboard → dein Projekt (Corejourney)

### Redirect URL whitelisten

`Authentication → URL Configuration → Redirect URLs`

Folgende URLs müssen eingetragen sein:

```
https://corejourney.care/auth/reset-password
corejourney://auth/reset-password
```

**Warum:** Supabase lässt nur vorher freigeschaltete URLs als Redirect-Ziel zu. Ohne Whitelist-Eintrag fällt Supabase auf die Site URL zurück.

### Site URL

`Authentication → URL Configuration → Site URL`

```
https://corejourney.care
```

---

## Teil 2: Custom SMTP mit Resend

**Warum Custom SMTP:**
- Ohne Custom SMTP kommen Emails von `@supabase.io` → landen im Spam
- Mit Custom SMTP kommen Emails von `noreply@corejourney.care` → vertrauenswürdig

**Resend:** https://resend.com (kostenlos bis 3.000 Emails/Monat)

### Schritt 1: Resend Account erstellen

→ https://resend.com → Sign Up

### Schritt 2: Domain verifizieren

Resend Dashboard → **Domains** → **Add Domain** → `corejourney.care`

Resend gibt DNS-Einträge (DKIM, SPF, DMARC). Diese bei **Namecheap** eintragen:
- https://namecheap.com → Domain List → corejourney.care → Manage → Advanced DNS
- Einträge als TXT-Records eintragen
- Propagation: 5–30 Minuten

### Schritt 3: API Key erstellen

Resend Dashboard → **API Keys** → **Create API Key** → kopieren (wird nur einmal angezeigt)

### Schritt 4: Supabase SMTP konfigurieren

`Authentication → Email → SMTP Settings → Set up SMTP`

| Feld | Wert |
|---|---|
| Sender name | CoreJourney |
| Sender email | `noreply@corejourney.care` |
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | dein Resend API Key |

### Schritt 5: Email Template anpassen

`Authentication → Email → Templates → Reset Password`

**Betreff:**
```
Passwort zurücksetzen · Reset your password | CoreJourney
```

**Body (HTML):** — vollständiges Template siehe unten im Abschnitt "Email Template".

---

## Teil 3: Website corejourney.care (Netlify)

**Warum eine Website:** Universal Links und App Links erfordern eine öffentlich erreichbare Domain die AASA- und assetlinks-Dateien ausliefert. Außerdem muss Supabase nach der Token-Verifikation irgendwohin redirecten.

**Netlify:** https://netlify.com (kostenlos)
**Projekt-URL:** https://grand-cajeta-a1a449.netlify.app
**Custom Domain:** https://corejourney.care

### Dateien im Netlify-Projekt

Lokaler Ordner: `/Users/alexandermessinger/dev/claudvibes/corejourney-web/`

```
corejourney-web/
├── _headers                          # Content-Type für .well-known
├── _redirects                        # Routing-Regeln
├── index.html                        # Landingpage (weiße Seite mit "CoreJourney")
└── well-known/                       # OHNE Punkt (Netlify serviert keine Dot-Ordner)
    ├── apple-app-site-association    # iOS Universal Links Konfiguration
    └── assetlinks.json               # Android App Links Konfiguration
```

### _redirects Inhalt

```
/.well-known/apple-app-site-association /well-known/apple-app-site-association 200
/.well-known/assetlinks.json /well-known/assetlinks.json 200
/auth/* /index.html 200
```

**Warum /auth/* → /index.html:** Wenn der Browser (nach Gmail-Redirect) auf corejourney.care/auth/reset-password landet, soll keine 404 kommen sondern die index.html.

### _headers Inhalt

```
/.well-known/apple-app-site-association
  Content-Type: application/json

/.well-known/assetlinks.json
  Content-Type: application/json

/well-known/apple-app-site-association
  Content-Type: application/json

/well-known/assetlinks.json
  Content-Type: application/json
```

### apple-app-site-association (AASA) — iOS Universal Links

`well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "5X6VFP7F58.com.alexandermessinger.corejourney",
        "paths": ["/auth/*"]
      }
    ]
  }
}
```

- `5X6VFP7F58` = Apple Team ID
- `com.alexandermessinger.corejourney` = Bundle ID

### assetlinks.json — Android App Links

`well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.alexandermessinger.corejourney",
    "sha256_cert_fingerprints": ["PLACEHOLDER"]
  }
}]
```

**TODO:** `PLACEHOLDER` ersetzen mit echtem SHA256-Fingerprint des Release-Zertifikats (benötigt für Android Production).

### Netlify Deploy

Neuen Stand deployen:
```bash
cd /Users/alexandermessinger/dev/claudvibes/corejourney-web
zip -r deploy.zip . -x "*.DS_Store"
```
→ Netlify Dashboard → Projekt → Deploys → Zip hochladen

**Wichtig beim Zippen:** Immer aus dem `corejourney-web/`-Ordner heraus zippen, nicht einen Ordner drüber. Sonst enthält das Zip einen Unterordner und Netlify findet die Dateien nicht.

---

## Teil 4: iOS Konfiguration

### Universal Links (funktionieren direkt aus Apple Mail, iMessage, Safari)

**Datei:** `ios/Runner/Runner.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:corejourney.care</string>
</array>
```

**Xcode Projekt:** `ios/Runner.xcodeproj/project.pbxproj`
→ `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` in allen 3 Build-Configs eingetragen (Debug, Release, Profile)

### Custom URL Scheme (funktioniert auch durch Gmail/Brave/Chrome)

**Datei:** `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>corejourney</string>
        </array>
    </dict>
</array>
```

---

## Teil 5: Android Konfiguration

**Datei:** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- App Links: direkte Links (wie Universal Links auf iOS) -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="corejourney.care"
        android:pathPrefix="/auth/"/>
</intent-filter>

<!-- Custom URL Scheme: funktioniert durch alle Browser/Email-Clients -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="corejourney"/>
</intent-filter>
```

---

## Teil 6: Flutter App — Deep Link Handling

**Package:** `app_links: ^7.0.0` (in `pubspec.yaml`)

**Datei:** `lib/app.dart`

Die App hört auf eingehende Deep Links (Cold Start + Warm Start):

```dart
Future<void> _handleDeepLink(Uri uri) async {
  // corejourney://auth/reset-password → host='auth', path='/reset-password'
  // https://corejourney.care/auth/reset-password → path='/auth/reset-password'
  final isResetPassword = uri.path == '/auth/reset-password' ||
      (uri.scheme == 'corejourney' &&
          uri.host == 'auth' &&
          uri.path == '/reset-password');

  if (isResetPassword) {
    try {
      ref.read(passwordRecoveryActiveProvider.notifier).state = true;
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
      ref.read(passwordRecoveryActiveProvider.notifier).state = false;
    }
  }
}
```

**Wichtige Erkenntnis:** Für `corejourney://auth/reset-password` parsed Dart die URI so:
- `scheme` = `corejourney`
- `host` = `auth`
- `path` = `/reset-password`

Deshalb muss der Pfad-Check beide Formate abdecken.

### Router (`lib/core/navigation/app_router.dart`)

Der Router hört auf Supabase-Auth-Events UND auf `passwordRecoveryActiveProvider`-Änderungen:

```dart
// Redirect-Logik:
if (isPasswordRecovery && loc != Routes.resetPassword) {
  return Routes.resetPassword;  // → zeigt ResetPasswordScreen
}
```

**Warum `_CombinedListenable`:** GoRouter muss neu evaluieren wenn der Provider sich ändert, nicht nur wenn Supabase ein Auth-Event schickt.

### redirectTo in der App

**Datei:** `lib/features/auth/presentation/screens/login_screen.dart`

```dart
redirectTo: 'corejourney://auth/reset-password',
```

**Warum Custom Scheme statt https:** Gmail wraps alle Links durch Google's Tracking-URL. Universal Links (`https://`) werden dadurch gebrochen. Custom Schemes (`corejourney://`) werden erst nach der Supabase-Verifikation im Browser ausgelöst — zu diesem Zeitpunkt ist Gmail schon aus dem Bild.

---

## Teil 7: Email Template

Wird in Supabase unter `Authentication → Email → Templates → Reset Password` eingefügt.

Die Variable `{{ .ConfirmationURL }}` wird von Supabase automatisch durch den echten Link ersetzt.

**Betreff:**
```
Passwort zurücksetzen · Reset your password | CoreJourney
```

**HTML-Body:** Bilinguales Template (Deutsch/Englisch) mit CoreJourney-Branding. Farbe `#1a1a2e` (dunkelblau) — anpassen falls sich `AppColors.primary` ändert.

---

## Bekannte Einschränkungen & TODOs

| Thema | Status | Beschreibung |
|---|---|---|
| Android assetlinks.json | ⚠️ TODO | SHA256-Fingerprint des Release-Certs eintragen |
| Gmail Universal Links | ✅ gelöst | Custom URL Scheme umgeht das Problem |
| Brave Browser | ✅ funktioniert | Custom URL Scheme öffnet App korrekt |
| Apple Mail | ✅ funktioniert | Universal Links + Custom Scheme |
| Email im Spam | 🔧 in Arbeit | Custom SMTP via Resend löst das |

---

## Verwendete Dienste

| Dienst | URL | Zweck |
|---|---|---|
| Supabase | https://supabase.com | Backend, Auth, Datenbank |
| Netlify | https://netlify.com | Hosting corejourney.care |
| Namecheap | https://namecheap.com | Domain-Registrar corejourney.care |
| Resend | https://resend.com | Custom SMTP (Email-Versand) |

---

## Nach App-Updates: Checkliste

- [ ] Nach Änderungen an Deep Links: `make run` (App neu installieren)
- [ ] Nach Änderungen an `well-known/`-Dateien: Neu auf Netlify deployen + AASA-Cache auf iPhone löschen (Gerät neu starten)
- [ ] Nach Änderungen an Entitlements: Xcode-Build erforderlich (nicht nur Hot Reload)
