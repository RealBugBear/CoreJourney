# Navigation & Settings Cleanup — Implementation Plan

> **For agentic workers:** Implement task-by-task. Keep changes small and verify after each task. The current worktree is already dirty, so do not revert unrelated edits.

**Goal:** Die App-Struktur ruhiger und produktklar machen: Settings wird auf echte App-Präferenzen reduziert, Account-Verwaltung wandert ins Profil, Trainer-Kommunikation wird als eigener Produktbereich gedacht, Community wird sprachlich und strukturell von Chat/Kanälen getrennt.

**Architecture:** Incremental cleanup. Zuerst Settings/Profile ordnen, dann Navigation/Trainer-Bereich. Dadurch wird die App sofort nutzerfreundlicher, ohne die bestehenden Chat-/Trainer-Flows unnötig zu brechen.

**Tech Stack:** Flutter, GoRouter, Riverpod, Supabase

**Source Review:** `docs/superpowers/specs/2026-04-25-app-navigation-settings-review.md`

---

## Product Decisions

| Thema | Entscheidung |
|---|---|
| Settings | Nur App-Verhalten: Training, Erinnerungen, Darstellung, Erweitert |
| Account | Profil → Account |
| Trainer | Eigener Bereich/Tab, nicht Settings |
| Direct Chat | Trainer-Bereich, nicht “Nachrichten” als generisches Konzept |
| Community | Pinnwand/Erfahrungen, keine Chat-/Kanal-Sprache |
| Admin | Profil → Admin, nur rollenbasiert sichtbar |
| Sonderfälle | Nicht prominent in Settings; Support-/Recovery-Kontext |

---

## Target Navigation

### Phase 1

| Tab | Route | Inhalt |
|---|---|---|
| Home | `/dashboard` | Tagesstatus, Training, Fortschritt |
| Community | `/community` | Erfahrungs-Pinnwand / Feed |
| Profil | `/profile` | Identität, Journal, Account, Settings |

Trainer-Kommunikation bleibt zunächst über Profil/Shortcut erreichbar, bis der Trainer-Bereich gebaut ist.

### Phase 2

| Tab | Route | Sichtbarkeit |
|---|---|---|
| Home | `/dashboard` | immer |
| Community | `/community` | immer |
| Trainer | `/trainer-home` | sichtbar wenn Trainer verknüpft, Trainerrolle aktiv oder Discovery aktiviert |
| Profil | `/profile` | immer |

Der Trainer-Tab ersetzt langfristig den separaten DM-Gedanken.

---

## File Map

| Status | Datei | Änderung |
|---|---|---|
| Modify | `lib/features/settings/presentation/screens/settings_screen.dart` | Auf Präferenzen reduzieren; Account/Trainer/Rollen/Sonderfälle entfernen |
| Modify | `lib/features/profile/presentation/screens/profile_screen.dart` | Account-Sektion ergänzen; Admin-/Trainer-Zugänge rollenbasiert verlinken |
| Modify | `lib/features/community/presentation/screens/community_screen.dart` | Sprache von “Kanal” auf “Pinnwand/Erfahrungen” umstellen |
| Create | `lib/features/trainer/presentation/screens/trainer_home_screen.dart` | Späterer Trainer-/Betreuungsbereich |
| Modify | `lib/core/navigation/app_router.dart` | Route für Trainer-Home ergänzen, später Shell-Tab |
| Modify | `lib/core/navigation/app_shell.dart` | Später 4. Trainer-Tab, route-basiert |
| Optional | `lib/features/settings/presentation/widgets/*` | Settings in kleinere Widgets teilen, wenn Datei weiter wächst |

---

## Task 1: Settings Screen auf Präferenzen reduzieren

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

**Ziel:** Settings beantwortet nur noch: “Wie soll sich die App verhalten?”

- [ ] Entferne aus der sichtbaren Settings-Liste:
  - `_RoleAreasSection`
  - `_TrainerConnectionSection`
  - `_AccountSection`
  - `_SpecialCasesSection`
- [ ] Behalte und ordne neu:
  - Training: Trainingsmodus, Feedback, Wochenziel
  - Erinnerungen: Reminder an/aus, Zeitfenster
  - Darstellung: Sprache, Theme
  - Erweitert: Sync-Status
- [ ] Benenne Sektionen klar:
  - `Training`
  - `Erinnerungen`
  - `Darstellung`
  - `Erweitert`
- [ ] Entferne “Zurück zu Moro” aus der normalen UI.
- [ ] Falls Sync zu technisch wirkt, platziere ihn unter `Erweitert` ganz unten.

**Akzeptanzkriterien:**
- Settings ist deutlich kürzer.
- Keine Trainer-/Admin-/Account-Aktionen mehr in Settings.
- Keine destruktiven Aktionen mehr in Settings.
- Trainingsmodus, Sprache, Theme, Feedback, Erinnerungen, Wochenziel und Sync bleiben erreichbar.

**Verification:**

```bash
flutter analyze lib/features/settings/presentation/screens/settings_screen.dart
```

---

## Task 2: Account-Aktionen ins Profil verschieben

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`

**Ziel:** Profil wird der Ort für Identität und Account-Verwaltung.

- [ ] Ergänze Profil-Sektion `Account`.
- [ ] Verschiebe/dupliziere funktional:
  - Passwort ändern → `Routes.changePassword`
  - Abmelden → `authNotifierProvider.signOut()`
  - Account löschen → bestehende `delete_user` RPC mit Bestätigung
- [ ] Account löschen als destruktive Aktion ganz unten in der Account-Sektion.
- [ ] Settings bleibt über Gear/Icon im Profil erreichbar.

**Akzeptanzkriterien:**
- Nutzer findet Passwort/Logout/Delete im Profil.
- Account löschen hat weiterhin Bestätigungsdialog.
- Settings enthält diese Aktionen nicht mehr.

**Verification:**

```bash
flutter analyze lib/features/profile/presentation/screens/profile_screen.dart
```

---

## Task 3: Rollenzugänge aus Settings herauslösen

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`
- Reuse logic from: `lib/features/settings/presentation/screens/settings_screen.dart`

**Ziel:** Trainer/Admin-Zugänge sind rollenbasierte Arbeitsbereiche, keine Settings.

- [ ] Für `role == 'admin'`: Profil-Sektion `Arbeitsbereich` mit `Admin Panel`.
- [ ] Für `role == 'trainer'`: Profil-Sektion `Arbeitsbereich` mit `Trainerbereich`.
- [ ] Für normale Nutzer: `Trainer werden` nicht prominent in Settings; optional Profil → `Beruflicher Zugang`.
- [ ] Trainer-Aktivierungscode-Dialog aus Settings nach Profil migrieren oder in ein eigenes Widget auslagern.

**Akzeptanzkriterien:**
- Admin Panel und Trainerbereich sind noch erreichbar.
- Normale Nutzer sehen diese Bereiche nicht.
- Settings bleibt frei von Rollenlogik.

---

## Task 4: Trainer-Verknüpfung vorbereiten für eigenen Bereich

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_home_screen.dart`
- Modify: `lib/core/navigation/app_router.dart`

**Ziel:** Trainer-Beziehung bekommt einen eigenen Kontext.

### Nutzer ohne Trainer

- CTA: Trainer verbinden
- Hinweis: Einladungscode vom Trainer
- Späterer Platzhalter: Trainer in der Nähe finden

### Nutzer mit Trainer

- Trainername / Status
- Chat öffnen
- Terminübersicht / Terminvorschläge
- Video-Call anfragen
- Trainer wechseln

### Trainerrolle

- Link zum Trainer-Dashboard
- Klientenliste
- Termine

**Akzeptanzkriterien:**
- Route `/trainer-home` existiert.
- Bestehende Trainer-Verbindungslogik wird wiederverwendet.
- Noch kein Bottom-Tab-Umbau nötig.

---

## Task 5: Community sprachlich von Chat/Kanal lösen

**Files:**
- Modify: `lib/features/community/presentation/screens/community_screen.dart`

**Ziel:** Community wirkt wie Pinnwand/Erfahrungsfeed, nicht wie Chat-Kanalliste.

- [ ] AppBar-Titel prüfen: `Community` oder `Erfahrungen`.
- [ ] Leerer Zustand: “Noch keine geteilten Erfahrungen” statt “Noch kein Community-Kanal”.
- [ ] Liste/Tiles: keine Begriffe wie `Kanal`, `Nachrichten`, `Unread`.
- [ ] Kurzfristig darf intern weiter `ChatChannel` verwendet werden; UI darf es nicht zeigen.
- [ ] Langfristig wird Community auf `community_posts` umgestellt.

**Akzeptanzkriterien:**
- Nutzer versteht Community als Feed/Pinnwand.
- Keine freie Chat-Erwartung entsteht.

---

## Task 6: AppShell-Entscheidung umsetzen

**Files:**
- Modify: `lib/core/navigation/app_shell.dart`
- Modify: `lib/core/navigation/app_router.dart`

**Empfehlung:** Phase 1 bei drei Tabs lassen:

- Home
- Community
- Profil

Trainer-Home wird zunächst über Profil/Trainerstatus erreichbar. Der vierte Tab kommt erst, wenn Trainer-Discovery oder eine ausgereifte Trainer-Zentrale existiert.

**Spätere 4-Tab-Variante:**

- Home
- Community
- Trainer
- Profil

**Akzeptanzkriterien Phase 1:**
- Keine halbfertige Trainer-Tab-Fläche.
- Keine DM-Route außerhalb der Produktlogik prominent sichtbar.
- Route-Struktur blockiert späteren Trainer-Tab nicht.

---

## Task 7: Alte Settings-Funktionen bereinigen

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Potentially create shared widgets for dialogs

**Ziel:** Entfernte Widget-Klassen nicht im Settings-File liegen lassen, wenn sie migriert wurden.

- [ ] `_AccountSection` entfernen, sobald Profil sie ersetzt.
- [ ] `_SpecialCasesSection` entfernen.
- [ ] `_TrainerConnectionSection` entfernen oder nach Trainer-Home migrieren.
- [ ] `_RoleAreasSection` entfernen oder in Profil/Trainer-Home migrieren.
- [ ] Aktivierungs-/Invite-Dialoge in passende Widgets auslagern, wenn Wiederverwendung nötig ist.

**Akzeptanzkriterien:**
- Settings-Datei ist wieder fokussiert.
- Keine toten Widget-Klassen bleiben zurück.

---

## Recommended Implementation Order

1. Task 1: Settings entschlacken.
2. Task 2: Account ins Profil.
3. Task 3: Rollenzugänge ins Profil.
4. Task 5: Community-Texte korrigieren.
5. Task 4: Trainer-Home als eigene Route vorbereiten.
6. Task 6: AppShell zunächst bewusst bei 3 Tabs stabilisieren.
7. Task 7: tote Settings-Klassen entfernen.

Diese Reihenfolge bringt sofort bessere UX, ohne direkt den Router großflächig umzubauen.

---

## Deferred Enterprise Hardening

| Thema | Spätere Maßnahme |
|---|---|
| Trainer-Tab | Aktivieren, sobald Discovery/Trainer-Zentrale fertig ist |
| Admin-Konsole | Eigene Admin-Navigation statt Profil-Link |
| Support-Modus | Diagnose und Recovery-Funktionen nur auf Anfrage sichtbar |
| Feature Flags | Trainer/Community/Discovery pro Rollout steuern |
| Analytics | Prüfen, ob Nutzer Settings finden und welche Bereiche genutzt werden |
| Accessibility QA | Settings/Profile/Navigation mit großen Schriften und Screenreader prüfen |

---

## Done Definition

- Settings ist kein Sammelbecken mehr.
- Account-Aktionen sind im Profil.
- Trainer-/Admin-Zugänge sind rollenbasiert außerhalb Settings.
- Community klingt nicht mehr nach Chat.
- Navigation bleibt stabil und ist bereit für einen späteren Trainer-Tab.
