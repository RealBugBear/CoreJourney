# CoreJourney Handoff Status

## Projektziel
- CoreJourney vom aktuellen Stand zu einer stabilen, hands-free-faehigen, offline-robusten Mobile-App bringen (iOS zuerst, danach Android-Paritaet).
- Fokus: Trainingsfluss ohne Friktion, verlaessliches Tracking, sinnvolle Reminder, bessere Fortschritts-UI.

## Geplante Phasen (urspruenglich)
1. iOS-Stabilisierung
2. Hands-free Modus
3. Audio/Musik-Kompatibilitaet
4. Fortschritts-UI Redesign
5. Reminder-System v2 (adaptiv, anti-spam)
6. Offline-First Haertung
7. Android-Paritaet
8. Release-Readiness

## Umgesetzte Sessions (1-16)

### Session 1 - Stabilitaets-Hotfixes
- Doppel-Reminder entfernt.
- Trainingsabschluss-Race-Condition gefixt (Completion erst nach Persistierung).

### Session 2 - Reminder-System v1
- Zentrale Reminder-Scheduling-Methode eingefuehrt.
- User-Settings statt harter Defaults genutzt.
- Logging fuer Reminder-Lifecycle verbessert.

### Session 3 - Hands-free Grundgeruest
- `Tutorial` vs `Routine` Modus.
- Routine startet direkt mit Uebung 1.
- Bildschirm bleibt waehrend Training aktiv (`wakelock`).

### Session 4 - Audio/Haptik/Voice Outputs
- Feedback-Service fuer Haptik, Cue-Sounds, TTS aufgebaut.
- Trigger bei Start, Uebungswechsel, Abschluss integriert.

### Session 5 - Musik-Kompatibilitaet
- Audio-Mix-Verhalten verbessert (`mixWithOthers`-Strategie).
- TTS-Audio-Session iOS-kompatibel konfiguriert.
- Feedback-Modi in Settings:
  - `Ton aus`
  - `Nur Haptik`
  - `Sprache + Cues + Haptik`

### Session 6 - Progress-UI Redesign
- Dashboard visuell ueberarbeitet (KPI-Grid, Wochen-Momentum, bessere Hero-Struktur).

### Session 7 - Logikvereinfachung Dashboard
- Zentrale Snapshot-Quelle fuer Dashboard eingefuehrt (statt verstreuter Berechnungen).

### Session 8 - Offline/Sync Haertung
- Sync-Queue-Coalescing pro Dokument.
- Delete-Prioritaet in Queue.
- Retry-Deadlock verhindert (Drop nach Retry-Limit).

### Session 9 - Reminder v2 adaptiv
- Von "daily repeat" auf "naechsten Reminder planen" umgestellt.
- Bedarfslogik + Anti-Spam (z. B. kuerzlich aktiv, heute bereits trainiert).

### Session 10 - Android-Paritaet-Basics
- Android `WAKE_LOCK` Permission ergaenzt.
- Abgleich fuer neue Features auf Android-Basis.

### Session 11 - Dev-Diagnostik
- Debug-Tools um Local Sync Diagnostics erweitert (Pending Jobs, Force Sync, Clear Queue).

### Session 12 - Reminder-Intensitaet
- Neue Cadence-Profile: `minimal` / `balanced`.
- Direkte Integration in adaptive Reminder-Logik + Settings.

### Session 13 - Health Panel in normalen Settings
- Sichtbarer Systemstatus ohne Dev-Screen:
  - Reminder geplant (Ja/Nein)
  - Pending Sync Jobs
  - Aeltester Queue-Eintrag

### Session 14 - UX-Haertung Settings
- Robuste Fehlerbehandlung + Rollback bei Settings-Aenderungen.
- Klarere Permission-/Fehlerhinweise.

### Session 15 - Edge-Case-Haertung + Tests
- Reminder-Planung in testbare Entscheidungsfunktion extrahiert.
- Erweiterte Tests fuer Reminder-Edge-Cases.
- Tests gruen.

### Session 16 - Release-Readiness
- Skript + Makefile-Target + fokussierte Checkliste fuer Go/No-Go eingefuehrt.

## Aktueller Stand
- Technisch in einem stabilisierten Pre-QA-Status.
- Kernbereiche (Hands-free, Reminder v2, Sync-Haertung, Dashboard-Konsistenz) sind implementiert.
- Automated-Checks + zentrale Regressionstests laufen.
- Naechster Schritt ist primaer systematisches Geraete-QA (iOS + Android) und anschliessende Bugfix-Buendelung.

## Wichtige Artefakte
- Release-Checkliste:
  - `/Users/alexandermessinger/dev/corejourney/docs/RELEASE_READINESS_CHECKLIST.md`
- Release-Readiness-Skript:
  - `/Users/alexandermessinger/dev/corejourney/scripts/release_readiness.sh`
- Makefile-Entry:
  - `/Users/alexandermessinger/dev/corejourney/Makefile`
- Dashboard (neue UI + Snapshot-Nutzung):
  - `/Users/alexandermessinger/dev/corejourney/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Progress-/Reminder-Logik:
  - `/Users/alexandermessinger/dev/corejourney/lib/features/progress/domain/services/progress_service.dart`
- Sync-Haertung:
  - `/Users/alexandermessinger/dev/corejourney/lib/core/sync/sync_service.dart`
- Notification-Service:
  - `/Users/alexandermessinger/dev/corejourney/lib/core/services/notification_service.dart`
- Settings (Feedback/Cadence/Health):
  - `/Users/alexandermessinger/dev/corejourney/lib/features/settings/presentation/screens/settings_screen.dart`
- Training Feedback (Audio/Haptik/TTS):
  - `/Users/alexandermessinger/dev/corejourney/lib/features/training/presentation/services/training_feedback_service.dart`

## Offene Arbeit fuer Dritte (empfohlene Reihenfolge)
1. Vollstaendige Device-QA nach Checkliste (iOS + Android).
2. Gefundene Bugs clustern in:
   - Reminder-Verhalten
   - Audio/Musik
   - Offline/Sync
   - Dashboard-Konsistenz
3. Fix-Iteration + erneuter Lauf von:
   - `make release-readiness-mobile`
   - manueller Checkliste
4. Danach Release-Kandidat schneiden.
