# App Structure & Userflow — Design Spec

**Datum:** 2026-04-21
**Ansatz:** Shell-first (Option B) — Navigation und Routing zuerst reparieren, Content-Migration danach inkrementell.

---

## Ziel

Die App-Navigation von 4 gemischten Tabs auf eine klare 3+1-Struktur umbauen. Navigatorische Sackgassen schließen. Community und DM als eigenständige, sauber getrennte Bereiche etablieren.

---

## 1. Navigation-Struktur

### Bottom-Navigation

| Index | Tab | Route | Bedingung |
|-------|-----|-------|-----------|
| 0 | Home | `/dashboard` | immer |
| 1 | Community | `/community` | immer |
| 2 | Nachrichten | `/dm` | nur wenn `trainerLinked == true` |
| 3 | Profil | `/profile` | immer |

Der DM-Tab wird über einen `trainerLinkedProvider` (Riverpod) konditionell gerendert. Kein Trainer verknüpft → 3 Tabs. Trainer verknüpft → 4 Tabs mit Badge-Support via `unreadDmCountProvider`.

Das aktive Tab-Highlighting im `AppShell` muss **route-basiert** funktionieren (via `GoRouterState`), nicht über feste Indizes — da sich die Indizes verschieben wenn der DM-Tab ein- oder ausgeblendet wird.

### Global App-Bar

- Gear-Icon (→ `/settings`) auf allen Tabs sichtbar, gerendert im Shell-AppBar.
- Kein separates Profil-Icon im AppBar — der Profile-Tab übernimmt das.

---

## 2. Route-Struktur

### Shell-Routes (Bottom-Nav sichtbar)

```
/dashboard
/community
  /:channelId          ← shell-child, kein parentNavigatorKey
/dm                    ← konditionell
  /:channelId          ← shell-child, kein parentNavigatorKey
/profile
```

Alle Channel-Screens (Community und DM) laufen als Shell-Child-Routes. Bottom-Nav bleibt beim Öffnen eines Channels sichtbar. Back-Button geht zurück zur jeweiligen Inbox.

### Standalone-Routes (kein Shell)

```
/settings
/training/session
/consent
/intake-assessment
/intake-assessment/duration
/completion-questionnaire
/trainer/*
/admin
/profile/change-password
/dev-tools
```

### Wegfallende Routes

| Route | Grund |
|-------|-------|
| `/packages` | kein Tab mehr; bleibt als standalone für Trainer/Admin |
| `/chat` | aufgeteilt in `/community` und `/dm` |
| `/mood/history` | Screen fällt komplett weg, Graph auf Dashboard übernimmt |
| `/appointments/proposals` | wird in DM-Channel-Flow integriert |

---

## 3. Dead-End-Fixes

### `AppointmentProposalScreen`
- Nach erfolgreichem Bestätigen: `context.pop()` zurück zum aufrufenden DM-Channel.
- Bei direkter Navigation ohne Channel-Kontext: redirect auf `/dm`.
- Kein "stuck auf leerem Screen" nach letzter Bestätigung.

### `ChatChannelScreen`
- `parentNavigatorKey: _rootNavigatorKey` wird entfernt für Community- und DM-Channels.
- Screen wird über `/community/:channelId` und `/dm/:channelId` als Shell-Child gemountet.

### `ChatInboxScreen`
- Wird aufgeteilt in `CommunityScreen` und `DmScreen`.
- Alte Route `/chat` und `ChatInboxScreen` werden entfernt sobald beide neuen Screens stehen.

### `/mood/history`
- Route wird vollständig entfernt. Kein redirect nötig — MoodHistoryScreen fällt weg.

---

## 4. Dashboard-Layout

Kein reservierter Platz für Banner. Urgent-Infos (z.B. Terminvorschläge) werden über den DM-Tab-Badge signalisiert.

```
┌─────────────────────────────┐
│  [streak] [day X] [week X/Y]│  ← slim strip, eine Zeile
├─────────────────────────────┤
│                             │
│                             │
│       Mood-Diagramm         │  ← kompakt aber ohne Scrollen sichtbar
│   (Notiz-Marker tippbar)    │  ← geloggte Notizen als Punkte im Graph
│                             │
│                             │
├─────────────────────────────┤
│  [ Training starten ]       │  ← primäre CTA, prominent
│  [ ○ Quick-Entry ]          │  ← visuell sekundär, klein
└─────────────────────────────┘
```

**Entfernt vom Dashboard:**
- `JournalCard` — fällt weg
- `ProgramCard` — fällt weg
- `ModeSelector` — wandert in Settings
- AppBar-Shortcuts für Profile und Settings (Settings kommt als Gear-Icon, Profile als Tab)

**Mood-Diagramm:**
- Geloggte Notizen erscheinen als Marker im Graph.
- Antippen eines Markers öffnet die Notiz (Bottom Sheet).
- Vollständige Journal-History: Profile → Journal.

---

## 5. Community-Screen

- Neuer eigenständiger Screen unter `/community`.
- Startet leer — kein Content zum Launch.
- Placeholder-State mit klarem CTA ("Bald verfügbar" o.ä.) bis Content erstellt wird.
- Channels werden später als `/community/:channelId` geöffnet (Shell-Child, Bottom-Nav bleibt sichtbar).

---

## 6. DM-Screen

- Konditioneller Tab, nur sichtbar wenn `trainerLinked == true`.
- Zeigt die bestehende Trainer-DM-Kommunikation.
- Badge-Zähler via `unreadDmCountProvider`.
- Terminvorschläge werden über den DM-Channel-Flow abgewickelt, nicht als separater Screen.
- DM-Channels öffnen als Shell-Child unter `/dm/:channelId`.

---

## 7. Profile & Settings

### Profile-Tab
- Identität / Account-Zusammenfassung
- Journal-Zugang (→ History aller Einträge)
- Trainer-Name und Beziehungsstatus
- Direktlink in DM-Tab (wenn Trainer verknüpft)

### Settings (via Gear-Icon)
- Ganz oben: Tutorial / Routine Toggle
- Dann: Sprache, Theme
- Dann: Erinnerungen, Feedback, Sync
- Unten: Trainer connect / switch, Passwort ändern, Abmelden
- Unten: Trainer/Admin-Bereich (rollenbasiert)
- Unten: Zurück zu Moro (mit zweifacher Bestätigung)
- Ganz unten / destruktiv: Account löschen

---

## 8. Was nicht in diesem Scope liegt

- Exakte Texte für Bestätigungen und Systemnachrichten
- Visuelles Design des Quick-Entry-Controls
- Trainer-seitiger Package-Progress-Screen
- Chat-basierter Package-Change-Acceptance-Flow
- Community-Content-Erstellung und Feed-Struktur

---

## Implementierungsreihenfolge (Shell-first)

1. `AppShell` umbauen: neue Tab-Struktur, konditioneller DM-Tab, Gear-Icon
2. Router umbauen: neue Shell-Routes, Channel-Screens als Shell-Children
3. `CommunityScreen` anlegen (leer)
4. `DmScreen` anlegen (aus `ChatInboxScreen` extrahiert)
5. Dead-Ends fixen: `AppointmentProposalScreen`, Channel-Navigation
6. Dashboard aufräumen: JournalCard, ProgramCard, ModeSelector entfernen
7. Mood-Diagramm kompakter + Notiz-Marker integrieren
8. Alte Routes entfernen: `/chat`, `/mood/history`, `/appointments/proposals` als standalone
