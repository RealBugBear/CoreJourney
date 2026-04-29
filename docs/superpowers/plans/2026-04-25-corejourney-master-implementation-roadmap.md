# CoreJourney — Master Implementation Roadmap

> **For agentic workers:** This is the canonical implementation roadmap. Use this plan as the source of truth for sequencing. Older plans remain useful as technical references, but where they conflict with this roadmap, this roadmap wins.

**Datum:** 2026-04-25
**Status:** Draft for execution
**Projekt:** CoreJourney (Flutter + Supabase)

---

## Goal

CoreJourney soll zuerst als ruhige, verlässliche Trainings-App funktionieren, dann die Trainer-Kommunikation stabilisieren, danach Community-Pinnwand und Trainer-Netzwerk ausbauen. Die deutschlandweite Trainer-Vision bleibt Zielbild, aber die Umsetzung wird in Phasen geschnitten, damit der aktuelle MVP nicht durch zu viele parallele Umbauten instabil wird.

---

## Canonical References

Diese Dokumente sind aktiv und bilden zusammen die aktuelle Richtung:

| Bereich | Quelle |
|---|---|
| Offene Punkte Gesamt-App | `docs/superpowers/specs/2026-04-25-app-open-points-review.md` |
| Navigation & Settings | `docs/superpowers/specs/2026-04-25-app-navigation-settings-review.md` |
| Settings Cleanup Plan | `docs/superpowers/plans/2026-04-25-navigation-settings-cleanup.md` |
| Chat, Community, Video | `docs/superpowers/specs/2026-04-25-chat-community-video-enterprise-review.md` |
| Trainer Discovery | `docs/superpowers/specs/2026-04-24-trainer-discovery-design.md` |
| Auth Enterprise | `docs/superpowers/specs/2026-04-19-auth-enterprise-design.md` |
| Immersive Training | `docs/superpowers/specs/2026-04-22-immersive-training-redesign.md` |

### Superseded / Reference Only

Diese Pläne enthalten weiterhin nützliche Details, sind aber nicht mehr die Produktquelle:

| Datei | Status |
|---|---|
| `docs/superpowers/plans/2026-04-21-navigation-restructure.md` | Superseded by Navigation & Settings Cleanup |
| `docs/superpowers/specs/2026-04-21-app-structure-and-userflow-design.md` | Superseded by 2026-04-25 navigation review |
| `docs/superpowers/specs/2026-04-13-kommunikation-design.md` | Superseded by chat/community/video review |
| `docs/superpowers/specs/2026-04-14-chat-video-premium-design.md` | Reference for technical pieces only |
| `docs/superpowers/plans/2026-04-14-video-chat.md` | Reference for Agora implementation only |
| `docs/superpowers/plans/2026-04-13-chat-foundation.md` | Reference for existing chat schema only |

---

## Phase Overview

| Phase | Ziel | Ergebnis |
|---|---|---|
| A | App-Struktur stabilisieren | Settings schlank, Profil/Account klar, Community-Sprache passend |
| B | Auth/Account verifizieren | Reset, Change Password, Delete, Consent funktionieren Ende-zu-Ende |
| C | 1:1 Kommunikation stabilisieren | Direct Chat + Video-Call zuverlässig |
| D | Trainer-Zentrale vorbereiten | Eigener Trainer-Kontext für Nutzer/Trainer |
| E | Community-Pinnwand konsolidieren | Journal/Experience Sharing als Feed statt Chat |
| F | Training QA & Polish | Immersive Training und Tagesabschluss sauber |
| G | Trainer Discovery MVP | Privacy-safe Trainer-Suche + Verifizierung + Anfragen |
| H | Release Readiness | Config, Migration, Observability, Push-Entscheidung |
| I | Deferred Enterprise | Audit, Rate Limits, Rollenmodell, Monitoring |

---

## Phase A — App-Struktur Stabilisieren

**Ziel:** Nutzerführung beruhigen, Settings entschlacken, Profil und Community eindeutig machen.

**Primary plan:** `docs/superpowers/plans/2026-04-25-navigation-settings-cleanup.md`

### Tasks

- [ ] Settings auf vier Sektionen reduzieren:
  - Training
  - Erinnerungen
  - Darstellung
  - Erweitert
- [ ] Account-Aktionen ins Profil verschieben:
  - Passwort ändern
  - Abmelden
  - Account löschen
- [ ] Rollenzugänge aus Settings entfernen:
  - Admin Panel → Profil
  - Trainerbereich → Profil oder später Trainer-Home
  - Trainer werden → Profil → Beruflicher Zugang
- [ ] Trainer-Verknüpfung aus Settings herauslösen und für Trainer-Home vorbereiten.
- [ ] Community-Screen sprachlich auf “Erfahrungen/Pinnwand” umstellen.
- [ ] AppShell vorerst stabil bei 3 Tabs lassen:
  - Home
  - Community
  - Profil

### Acceptance Criteria

- Settings enthält keine Account-, Trainer-, Admin- oder Sonderfall-Aktionen mehr.
- Profil enthält Account-Verwaltung.
- Community wirkt nicht mehr wie ein Chat/Kanal.
- Bestehende Direct-Chat-Zugänge bleiben erreichbar.

### Verification

```bash
flutter analyze lib/features/settings/presentation/screens/settings_screen.dart
flutter analyze lib/features/profile/presentation/screens/profile_screen.dart
flutter analyze lib/features/community/presentation/screens/community_screen.dart
```

---

## Phase B — Auth, Account & Consent Verifizieren

**Ziel:** Account-Flows müssen vor weiteren großen Features verlässlich sein.

**Primary reference:** `docs/superpowers/specs/2026-04-19-auth-enterprise-design.md`

### Tasks

- [ ] Passwort-Reset per Universal/App Link auf echtem iOS-Gerät testen.
- [ ] Passwort-Reset per Android App Link testen.
- [ ] In-App Passwort ändern mit Re-Auth testen.
- [ ] `delete_user()` in DEV deployen und Account-Löschung testen.
- [ ] `delete_user()` Deployment für PROD dokumentieren.
- [ ] Supabase Auth Redirect URLs für DEV/PROD prüfen.
- [ ] Consent-Version und Consent-Storage prüfen.
- [ ] Account löschen nach erfolgreicher RPC auch lokale Daten sauber leeren lassen.

### Acceptance Criteria

- Nutzer kann Passwort zurücksetzen, ohne im Browser festzuhängen.
- Nutzer kann Passwort in der App ändern.
- Account löschen funktioniert in DEV Ende-zu-Ende.
- Consent-Gate funktioniert für neue und wiederkehrende Nutzer.

### Manual Verification

- Frischer Account
- Bestehender Account
- Passwort vergessen
- Passwort ändern
- Account löschen
- App-Neustart nach Consent

---

## Phase C — 1:1 Kommunikation Stabilisieren

**Ziel:** Trainer-Nutzer Direct Chat und 1:1 Video müssen zuverlässig funktionieren.

**Primary reference:** `docs/superpowers/specs/2026-04-25-chat-community-video-enterprise-review.md`

### C1 — Direct Chat

- [ ] Sicherstellen, dass Direct Chat nur Trainer ↔ Nutzer ist.
- [ ] Alte Direct Channels bei Trainerwechsel nicht löschen, aber Schreibzugriff prüfen.
- [ ] Chat-Zugang im Produkt als Trainer-Kommunikation darstellen, nicht generische DMs.
- [ ] Appointment-/Video-Aktionen im Direct Chat prüfen.

### C2 — Video-Call Fixes

- [ ] Android Kamera-/Mikrofon-Permissions ergänzen.
- [ ] Token-Fallback nur in explizitem Dev-Modus erlauben oder sichtbar fehlschlagen.
- [ ] DB: maximal ein aktiver Call pro Direct-Channel.
- [ ] `start_direct_call(channel_id)` serverseitig absichern.
- [ ] `end_call(call_id)` so absichern, dass beide Channel-Mitglieder beenden können.
- [ ] App-weiter Active-Call-Listener für Direct Channels.
- [ ] UI-Zustände für Call sauber machen:
  - lädt
  - klingelt
  - verbunden
  - beendet
  - fehlgeschlagen

### Acceptance Criteria

- Trainer startet Call.
- Nutzer sieht eingehenden Call auch außerhalb des geöffneten Chat-Screens, solange App aktiv ist.
- Beide treten bei.
- Audio und Video funktionieren auf zwei Geräten.
- Beide können auflegen.
- DB bleibt nicht mit hängendem aktivem Call zurück.

### Verification

```bash
flutter analyze lib/features/video lib/features/chat
```

Manual:

- iOS Gerät ↔ iOS Simulator, falls möglich
- iOS Gerät ↔ Android Gerät, sobald Android bereit
- Permission denied
- Token/Agora config missing
- Call beendet durch Trainer
- Call beendet durch Nutzer

---

## Phase D — Trainer-Zentrale Vorbereiten

**Ziel:** Trainer-Beziehung bekommt einen klaren Ort, bevor Discovery kommt.

### Tasks

- [ ] `TrainerHomeScreen` anlegen.
- [ ] Route `/trainer-home` ergänzen.
- [ ] Nutzer ohne Trainer:
  - Einladungscode eingeben
  - später Trainer finden CTA als disabled/placeholder oder feature-flagged
- [ ] Nutzer mit Trainer:
  - Trainername
  - Chat öffnen
  - Termine/Terminvorschläge
  - Video-Call-Anfrage
  - Trainer wechseln
- [ ] Trainerrolle:
  - Trainer-Dashboard
  - Klientenliste
  - Termine
- [ ] Profil auf TrainerHome verlinken.

### Acceptance Criteria

- Trainer-Verknüpfung ist nicht mehr in Settings nötig.
- Nutzer versteht, wo Trainer-Kommunikation lebt.
- Trainer können ihren Arbeitsbereich erreichen.
- AppShell bleibt vorerst 3 Tabs, TrainerHome ist route-basiert erreichbar.

---

## Phase E — Community-Pinnwand Konsolidieren

**Ziel:** Community wird ein Erfahrungsfeed aus freiwillig geteilten Journal-/Trainingseinträgen.

**Primary reference:** `docs/superpowers/specs/2026-04-25-chat-community-video-enterprise-review.md`

### Tasks

- [ ] Entscheiden: `experience_shares` weiterentwickeln oder auf `community_posts` migrieren.
- [ ] Kurzfristig UI auf “Erfahrungen” umstellen.
- [ ] Teilen aus Training mit klarer Vorschau und Datenschutzhinweis.
- [ ] Eigene Beiträge ausblenden/entfernen.
- [ ] Trainer/Admin kann Beiträge ausblenden, nicht hart löschen.
- [ ] Keine Kommentare in Phase 1.
- [ ] Keine Likes als Wachstumsmechanik.
- [ ] RLS prüfen: Nutzer lesen nur relevante Paket-Feeds.

### Acceptance Criteria

- Community fühlt sich nicht wie Gruppenchat an.
- Nutzer veröffentlicht nichts automatisch.
- Anonymität/Anzeigename ist klar.
- Moderation ist minimal möglich.

---

## Phase F — Training QA & Polish

**Ziel:** Kerntraining zuverlässig und hochwertig machen.

**Primary reference:** `docs/superpowers/specs/2026-04-22-immersive-training-redesign.md`

### Tasks

- [ ] Alte vs. neue Training-Screens konsolidieren.
- [ ] Disclaimer-Logik prüfen und TODOs schließen.
- [ ] Immersive Session auf echten Geräten testen:
  - Routine
  - Tutorial
  - Pause
  - Tempo
  - Audio/Haptik
  - App Hintergrund/Vordergrund
- [ ] In-App-Musik-Status klären:
  - Assets vorhanden?
  - Feature sichtbar oder deferred?
- [ ] “Training als abgeschlossen markieren” UX prüfen.
- [ ] Experience Prompt nach Training mit Community-Privacy abstimmen.

### Acceptance Criteria

- Training startet zuverlässig.
- Session kann abgeschlossen werden.
- Fortschritt und Mood/Experience werden korrekt gespeichert.
- Audio/Haptik verhalten sich erwartbar.

---

## Phase G — Trainer Discovery MVP

**Ziel:** Privacy-safe Trainer-Netzwerk als MVP aufbauen.

**Primary reference:** `docs/superpowers/specs/2026-04-24-trainer-discovery-design.md`

### Tasks

- [ ] DB-Migration:
  - `trainer_profiles`
  - `trainer_profile_private`
  - PostGIS
  - private/public location
- [ ] Server-RPCs:
  - Profil erstellen/updaten
  - Standort aktualisieren mit serverseitiger Public-Approximation
  - `find_trainers_nearby`
  - Trainer verifizieren/suspendieren
  - Discovery-Anfrage erstellen
  - Anfrage annehmen/ablehnen
- [ ] Admin Review Screen:
  - Pending Trainer
  - Kontakt/private Daten
  - Verifizieren/Suspendieren
- [ ] Trainer Profile Setup.
- [ ] Trainer Discovery Screen:
  - Login-only
  - privacy-safe Pins
  - Radius
  - Profile
  - Anfrage senden
- [ ] Bestehenden Invite-Flow erhalten.
- [ ] Mehrere pending Anfragen erlauben, eine aktive Beziehung behalten.

### Acceptance Criteria

- Exakte Trainerstandorte werden nie öffentlich angezeigt.
- Nur verifizierte Trainer erscheinen in Discovery.
- Nutzer kann mehrere Trainer anfragen.
- Annahme einer Anfrage wechselt aktive Beziehung atomar.
- Invite-Code-Flow funktioniert weiter.

---

## Phase H — Release Readiness

**Ziel:** App für echten Testbetrieb vorbereiten.

### Tasks

- [ ] DEV/PROD Supabase-Migrationen dokumentieren.
- [ ] Edge Function Deployment-Checkliste:
  - `agora-token`
  - `chat-triage-bot`
  - `activate-trainer`
  - `create-trainer-code`
  - `set-subscription-tier`
- [ ] Secrets prüfen:
  - Supabase
  - Agora
  - RevenueCat falls reaktiviert
- [ ] Crash/Error-Reporting-Strategie entscheiden.
- [ ] Push-Strategie entscheiden:
  - Calls
  - Trainer-Anfragen
  - Chat
  - Reminder bleiben lokal
- [ ] Feature Flags app-seitig konsequenter nutzen.
- [ ] Support-Diagnose:
  - App-Version
  - Environment
  - Sync-Status
  - User-ID kopierbar

### Acceptance Criteria

- DEV-Testlauf reproduzierbar.
- PROD-Migrationen sind nicht implizit/manuell vergessen.
- Kritische Fehler sind für Support diagnostizierbar.

---

## Phase I — Deferred Enterprise Hardening

Diese Themen werden bewusst erst nach MVP-Stabilisierung gezogen:

- [ ] Rate Limits für Calls, Anfragen, Community-Posts.
- [ ] Audit Logs für Admin/Trainer-Aktionen.
- [ ] Feineres Rollenmodell:
  - owner
  - admin
  - trainer_reviewer
  - support
  - moderator
- [ ] Monitoring:
  - Call-Erfolgsquote
  - Trainer-Anfrage-Konversion
  - Regionen ohne Trainer
  - Community-Posts
  - Sync-Fehler
- [ ] DSGVO-Prozesse:
  - Export
  - Löschung
  - Consent-Versionierung
  - geteilte Community-Inhalte
- [ ] Abuse/Moderation:
  - Meldungen
  - Review Queue
  - Keyword-Flags

---

## First Execution Slice

Der erste konkrete Sprint sollte klein bleiben:

1. Settings entschlacken.
2. Account-Aktionen ins Profil.
3. Community-Texte korrigieren.
4. Android Video-Permissions ergänzen.
5. Video-Call-Lifecycle-Plan in SQL/RPC konkretisieren.

Warum diese Reihenfolge:

- Sie verbessert sofort das App-Gefühl.
- Sie reduziert Nutzerverwirrung.
- Sie macht keine großen DB-Produktmigrationen.
- Sie bereitet die spätere Trainer-/Community-Arbeit vor.

---

## Handoff Instructions For Another AI Session

### Source Of Truth

Diese Datei ist die primäre Quelle für Reihenfolge und Scope:

`docs/superpowers/plans/2026-04-25-corejourney-master-implementation-roadmap.md`

Für den ersten Umsetzungsschnitt zusätzlich verwenden:

`docs/superpowers/plans/2026-04-25-navigation-settings-cleanup.md`

Wenn ältere Pläne abweichen, nicht den älteren Plan befolgen. Die älteren Pläne sind nur technische Referenzen.

### Start Scope

Die nächste Session soll **nur Phase A** umsetzen, plus kleine sichere Teile aus dem First Execution Slice:

1. Settings entschlacken.
2. Account-Aktionen ins Profil verschieben.
3. Rollenzugänge aus Settings herauslösen.
4. Community-Texte von Chat/Kanal auf Erfahrungen/Pinnwand korrigieren.
5. Keine großen Router-/DB-Migrationen.
6. Kein Trainer-Discovery-Build.
7. Kein Video-Call-Lifecycle-Umbau in derselben Session, außer wenn ausdrücklich später beauftragt.

### Constraints

- Der Worktree ist bereits dirty. Nicht fremde Änderungen revertieren.
- Keine destruktiven Git-Kommandos.
- Keine großen Refactors außerhalb der genannten Dateien.
- Bestehende Logik wiederverwenden, besonders Dialoge für Trainer-Code, Logout, Account löschen.
- Wenn Code aus Settings nach Profil wandert, nicht dupliziert liegen lassen, sobald die Migration abgeschlossen ist.
- UI-Texte auf Deutsch halten, passend zum bestehenden Stil.
- Settings darf nach Phase A keine Account-, Trainer-, Admin- oder Sonderfall-Aktionen mehr enthalten.

### Expected Files For Phase A

Wahrscheinlich zu ändern:

- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/community/presentation/screens/community_screen.dart`

Optional, nur wenn sauber nötig:

- `lib/core/navigation/app_router.dart`
- neue kleine Widget-Dateien unter `lib/features/settings/presentation/widgets/` oder `lib/features/profile/presentation/widgets/`

### Verification

Mindestens ausführen:

```bash
flutter analyze lib/features/settings/presentation/screens/settings_screen.dart
flutter analyze lib/features/profile/presentation/screens/profile_screen.dart
flutter analyze lib/features/community/presentation/screens/community_screen.dart
```

Wenn möglich zusätzlich:

```bash
flutter analyze
```

Wenn `flutter analyze` wegen bereits bestehender, nicht verwandter Fehler fehlschlägt, die relevanten neuen Fehler von bestehenden Fehlern trennen und im Abschlussbericht nennen.

### Deliverable

Die nächste Session soll am Ende liefern:

- Kurze Zusammenfassung der UX-Änderungen.
- Liste der geänderten Dateien.
- Welche Verifikation lief und mit welchem Ergebnis.
- Offene Folgepunkte für Phase B/C, aber nicht selbst anfangen.

---

## Done Definition For This Roadmap

Diese Roadmap gilt als umgesetzt, wenn:

- Settings klar und kurz ist.
- Account-/Auth-Flows funktionieren.
- 1:1 Video zuverlässig läuft.
- Trainer-Kommunikation einen eigenen Kontext hat.
- Community eine Pinnwand ist, kein Chat.
- Training als Kernflow QA-geprüft ist.
- Trainer-Discovery privacy-safe als MVP steht.
- Release-Checkliste für DEV/PROD existiert.
