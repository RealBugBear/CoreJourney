# Auth — Enterprise-Level Komplettlösung

**Datum:** 2026-04-19  
**Status:** Approved  
**Scope:** Passwort-Reset via Deep Link, In-App Passwort-Änderung, Konto löschen, Validierungs-Bugfix

---

## Problemstellung

Vier bekannte Defizite im Auth-Bereich:

1. **Passwort vergessen** — UI existiert, aber der Reset-Link in der E-Mail hat keine Redirect-URL → Nutzer landen im Browser ohne Weiterleitung, der Flow bricht ab.
2. **Passwort ändern (eingeloggt)** — nur "Reset-E-Mail senden" implementiert, kein In-App-Formular.
3. **Konto löschen** — `delete_user()` RPC existiert als SQL-Migration lokal, wurde aber nicht gegen DEV/PROD deployed → Fehler "Nutzer nicht gefunden".
4. **Passwort-Bestätigung Bug** — Confirm-Feld hat kein `autocorrect: false`, iOS kann unsichtbare Zeichen einfügen; Vergleich trimmt nicht → falsch-positive "Passwörter stimmen nicht überein".

---

## Ziel

Alle vier Punkte auf Enterprise-Niveau lösen. Der Nutzer verlässt die App an keiner Stelle des Auth-Flows.

---

## Architecture

### Universal Links

`corejourney.care` wird als verifizierte App-Domain eingetragen. Zwei statische Dateien müssen auf der Domain unter `/.well-known/` gehostet werden:

**`apple-app-site-association`** (iOS):
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

**`assetlinks.json`** (Android):
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.alexandermessinger.corejourney",
    "sha256_cert_fingerprints": ["<RELEASE_CERT_SHA256>"]
  }
}]
```

Beide Dateien müssen mit `Content-Type: application/json` ausgeliefert werden.

### App-seitige Deep Link Verarbeitung

Das Supabase Flutter SDK verarbeitet eingehende Auth-URLs automatisch, wenn beim App-Start die Methode `getSessionFromUrl()` aufgerufen wird. In `app.dart` wird ein `app_links`-Listener registriert, der eingehende Deep Links an das SDK weiterleitet.

Der SDK emittiert danach auf `onAuthStateChange` den Event `AuthChangeEvent.passwordRecovery`. Der Router reagiert darauf und navigiert zum `ResetPasswordScreen`.

### Supabase Dashboard Konfiguration (manuell, einmalig)

- **Site URL:** `https://corejourney.care`
- **Redirect URL Whitelist:** `https://corejourney.care/auth/reset-password`
- Gilt für DEV- und PROD-Projekt separat.

---

## Flows

### Flow A: Passwort vergessen (nicht eingeloggt)

```
LoginScreen
  → Nutzer tippt "Passwort vergessen"
  → E-Mail-Feld erscheint
  → Nutzer gibt E-Mail ein, tippt "Senden"
  → App ruft resetPasswordForEmail(email, redirectTo: 'https://corejourney.care/auth/reset-password')
  → Snackbar: "E-Mail wurde gesendet"
  → Nutzer öffnet E-Mail → tippt Link
  → iOS/Android öffnet App direkt via Universal Link
  → Supabase SDK erkennt passwordRecovery-Event
  → Router navigiert zu ResetPasswordScreen
  → Nutzer gibt neues Passwort + Bestätigung ein
  → App ruft supabase.auth.updateUser(password: newPassword)
  → Erfolg → Navigator.pop → LoginScreen mit Snackbar "Passwort gesetzt, bitte einloggen"
```

### Flow B: Passwort ändern (eingeloggt)

```
ProfileScreen
  → Nutzer tippt "Passwort ändern"
  → Push-Navigation zu ChangePasswordScreen
  → Felder: Aktuelles Passwort (Re-Auth), Neues Passwort, Bestätigung
  → App ruft signInWithPassword(email, currentPassword) zur Verifikation
  → Bei Erfolg: supabase.auth.updateUser(password: newPassword)
  → Pop → Snackbar "Passwort erfolgreich geändert"
```

### Flow C: Konto löschen

```
ProfileScreen
  → Nutzer tippt "Konto löschen"
  → Bestätigungs-Dialog (bestehendes Verhalten, bleibt erhalten)
  → App ruft supabase.rpc('delete_user')
  → Lokale DB leeren (bestehendes clearUserData())
  → signOut()
  → Navigation zu LoginScreen
  → Snackbar "Konto wurde gelöscht"
```

---

## Komponenten

### Neue Screens

#### `ResetPasswordScreen` (`/auth/reset-password`)
- Erreichbar via Deep Link und direkt aus LoginScreen (nach passwordRecovery-Event)
- Felder: Neues Passwort, Passwort bestätigen
- Validierung: min. 8 Zeichen, Felder müssen übereinstimmen
- Submit ruft `authNotifier.updatePassword(newPassword)` auf
- Kein Back-Button (Nutzer war nicht eingeloggt)
- Bei Erfolg: `context.go(Routes.login)` mit Erfolgs-Snackbar

#### `ChangePasswordScreen` (`/profile/change-password`)
- Erreichbar via Push aus ProfileScreen
- Felder: Aktuelles Passwort, Neues Passwort, Passwort bestätigen
- Re-Auth vor Update: `signInWithPassword` mit aktuellem Passwort
- Bei Erfolg: `context.pop()` mit Erfolgs-Snackbar

### Änderungen an bestehenden Dateien

#### `auth_repository.dart` (Interface)
```dart
Future<void> updatePassword({required String newPassword});
```

#### `supabase_auth_repository.dart` (Implementierung)
```dart
@override
Future<void> updatePassword({required String newPassword}) async {
  await _client.auth.updateUser(UserAttributes(password: newPassword));
}
```

#### `auth_provider.dart` (Notifier)
```dart
Future<void> updatePassword({required String newPassword}) async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(
    () => _repo.updatePassword(newPassword: newPassword),
  );
}
```

#### `app_router.dart`
Zwei neue Routen:
- `/auth/reset-password` → `ResetPasswordScreen`
- `/profile/change-password` → `ChangePasswordScreen`

Der Router beobachtet `authStateProvider` und leitet bei `passwordRecovery`-Event auf `/auth/reset-password` weiter.

#### `app.dart` / Bootstrap
`app_links`-Package wird hinzugefügt. Beide Fälle werden abgedeckt:
- **Cold Start** (App war geschlossen): `AppLinks().getInitialLink()` beim Start prüfen
- **Warm Start** (App war im Hintergrund): `AppLinks().uriLinkStream` lauschen

```dart
// Cold start
final uri = await AppLinks().getInitialLink();
if (uri != null) {
  await Supabase.instance.client.auth.getSessionFromUrl(uri);
}
// Warm start
AppLinks().uriLinkStream.listen((uri) {
  Supabase.instance.client.auth.getSessionFromUrl(uri);
});
```

#### `login_screen.dart`
- `redirectTo` Parameter zu `sendPasswordReset()` hinzufügen
- Confirm-Feld bekommt `autocorrect: false` + `enableSuggestions: false`
- `_validatePasswordConfirm`: beide Werte trimmen vor Vergleich

#### `profile_screen.dart`
- "Passwort ändern" navigiert zu `Routes.changePassword` statt Reset-Email zu schicken

#### iOS `Runner.entitlements`
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:corejourney.care</string>
</array>
```

#### Android `AndroidManifest.xml`
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="corejourney.care" android:pathPrefix="/auth/"/>
</intent-filter>
```

---

## Deployment Tasks (manuell)

| Task | Wo | Wann |
|---|---|---|
| `delete_user.sql` ausführen | Supabase SQL Editor — DEV + PROD | Vor erstem Test |
| Site URL setzen | Supabase Dashboard Auth → URL Config — DEV + PROD | Vor erstem Test |
| Redirect URL Whitelist eintragen | Supabase Dashboard — DEV + PROD | Vor erstem Test |
| AASA + assetlinks.json hosten | `corejourney.care/.well-known/` | Vor iOS/Android Deep Link Test |

---

## Abhängigkeiten

- Package `app_links: ^6.x` (oder neueste Version) zu `pubspec.yaml` hinzufügen
- Kein neues Backend-Code — Supabase Auth `updateUser()` ist bereits im SDK enthalten

---

## Error Handling

Alle Auth-Fehler laufen durch den bestehenden `_localizeAuthError()`-Mechanismus. Neue Fehlercodes die abgefangen werden müssen:
- `same_password` — neues Passwort ist identisch mit altem
- `weak_password` — Supabase lehnt schwaches Passwort ab
- `invalid_credentials` — beim Re-Auth in ChangePasswordScreen

---

## Testing Checklist

- [ ] Passwort-Reset E-Mail kommt an und Link öffnet App
- [ ] `ResetPasswordScreen` erscheint nach Deep Link ohne Back-Button
- [ ] Passwort-Update schlägt fehl wenn < 8 Zeichen
- [ ] Passwort-Update schlägt fehl wenn Felder nicht übereinstimmen
- [ ] Passwort-Update erfolgreich → Weiterleitung zu Login
- [ ] Eingeloggt: "Passwort ändern" öffnet `ChangePasswordScreen`
- [ ] Falsches aktuelles Passwort → Fehlermeldung
- [ ] Passwort erfolgreich geändert → Snackbar + Pop
- [ ] Konto löschen → lokale Daten weg → auf LoginScreen
- [ ] Registrierung: Passwort-Bestätigung mit Copy-Paste funktioniert korrekt
- [ ] Registrierung: Sichtbare Passwörter (Auge-Icon) verursachen keinen Mismatch
