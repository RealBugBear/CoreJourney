# CoreJourney — Claude Pflichtregeln

## PFLICHT VOR JEDER ARBEITSSESSION

**Bevor du mit einer Aufgabe beginnst, stelle immer diese Frage:**

> „Wo bauen wir heute — DEV oder PROD?"

Warte auf die Antwort. Starte keine Builds, keine Code-Änderungen an Configs,
keine Supabase-bezogenen Anpassungen, bevor das geklärt ist.

---

## Richtiges Projektverzeichnis

**IMMER arbeiten in:** `/Users/alexandermessinger/dev/claudvibes/corejourney/app`

Nicht in `/Users/alexandermessinger/dev/corejourney` — das ist ein veraltetes Verzeichnis.

---

## Dev/Prod Trennung — Eiserne Regeln

### DEV (tägliche Arbeit)
```bash
make run
# = flutter run --profile -d <DEVICE_ID> -t lib/main_development.dart
```
- Bundle ID: `com.alexandermessinger.corejourney` (kein .dev-Suffix in diesem Projekt)
- Lädt `.env.dev` → Dev-Supabase-Projekt

### PROD (TestFlight / App Store)
```bash
make release
# = flutter build ipa -t lib/main_production.dart --release
# Danach: Xcode → Window → Organizer → Distribute App → App Store Connect → Upload
```
- Bundle ID: `com.alexandermessinger.corejourney`
- Signing: Release Config, Team 5X6VFP7F58, Automatic

---

## Verbote — niemals ohne explizite Aufforderung

- **NIEMALS** `flutter build` oder `make release` ohne explizites „bau jetzt für Prod"
- **NIEMALS** `.env.dev` oder `.env.prod` committen
- **NIEMALS** Prod-Build manuell — nur über `make release`
- **NIEMALS** Entry Points (`lib/main_development.dart` / `lib/main_production.dart`) verwechseln
- **NIEMALS** im falschen Verzeichnis (`/dev/corejourney`) arbeiten

---

## Entry Points

| Zweck | Entry Point | Makefile-Befehl |
|---|---|---|
| Dev-Arbeit (Gerät) | `lib/main_development.dart` | `make run` |
| Dev-Arbeit (Simulator) | `lib/main_development.dart` | `make run-sim` |
| TestFlight/Prod | `lib/main_production.dart` | `make release` |

## Wichtige Dateien

- `.env.dev` / `.env.prod` → Supabase Credentials (nicht committen)
- `ios/ExportOptions.plist` → method: app-store, signingStyle: automatic, teamID: 5X6VFP7F58
- Nach `make release`: Xcode Organizer öffnen → `build/ios/archive/Runner.xcarchive`
