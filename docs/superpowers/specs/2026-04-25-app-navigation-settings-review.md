# App Navigation & Settings — Product Structure Review
**Datum:** 2026-04-25
**Status:** Draft for alignment
**Projekt:** CoreJourney (Flutter)

---

## Überblick

Die App-Struktur soll für Nutzer ruhiger und eindeutiger werden. Aktuell vermischen sich Training, Community, Direct Messages, Profil, Trainer/Admin-Funktionen und technische Einstellungen noch zu stark. Besonders der Settings-Screen ist überladen: Er enthält echte Nutzerpräferenzen, Trainer-Verknüpfung, Rollenbereiche, Sync-Diagnose, Sonderfälle und destruktive Account-Aktionen in einer langen Liste.

Ziel ist eine Struktur, die sich für normale Nutzer klar anfühlt und trotzdem Trainer/Admin-Funktionen sowie spätere deutschlandweite Skalierung nicht blockiert.

---

## Leitprinzipien

| Prinzip | Konsequenz |
|---|---|
| Häufige Nutzeraufgaben gehören in Tabs | Training, Community/Pinnwand, Trainer-Kommunikation, Profil |
| Settings nur für echte Präferenzen | Sprache, Design, Trainingsmodus, Erinnerungen, Feedback |
| Account-Verwaltung gehört ins Profil | E-Mail, Anzeigename, Passwort, Abmelden, Löschen |
| Rollenbereiche sind Arbeitsbereiche | Trainer/Admin nicht tief in Settings verstecken |
| Sonderfälle nicht prominent zeigen | “Zurück zu Moro”, Sync-Diagnose, Dev-Tools nur kontextuell/erweitert |
| Community ist Pinnwand, nicht Chat | Navigation und Texte dürfen nicht “Kanal/Chat” suggerieren |

---

## Ist-Zustand

### Navigation

- `AppShell` zeigt aktuell nur drei Tabs: Home, Community, Profil.
- `DM` existiert als Route, liegt aber außerhalb der Shell.
- Settings wird über AppBar-Icons in einzelnen Screens geöffnet.
- Die Userflow-Spec beschreibt teilweise schon eine 3+1-Struktur, ist aber noch nicht sauber umgesetzt.

### Settings

Der aktuelle Settings-Screen enthält:

- Trainingsmodus
- Sprache
- Theme
- Trainingsfeedback
- Erinnerungen
- Wochenziel
- Sync-Status
- Rollenbereiche
- Trainer werden
- Trainer verbinden/wechseln
- Passwort ändern
- Abmelden
- Zurück zu Moro
- Account löschen

Das ist funktional, aber als Nutzeroberfläche zu breit. Ein normaler Nutzer braucht vieles davon selten oder nie.

---

## Zielstruktur

### Bottom Navigation

Phase 1:

| Tab | Zweck | Sichtbarkeit |
|---|---|---|
| Home | Tagesstatus, Training starten, Fortschritt | immer |
| Community | Erfahrungs-Pinnwand aus geteilten Journal-Einträgen | immer, ggf. leerer Zustand |
| Trainer | Trainer-Beziehung, Direct Chat, Termine, Video | nur wenn Trainer verknüpft oder Discovery aktiv |
| Profil | Identität, Journal, Account | immer |

Warum “Trainer” statt “Nachrichten”: Der Bereich wird mehr als Chat enthalten: Trainerstatus, Kontakt, Termine, Video-Call-Anfragen und später Discovery. “Nachrichten” wäre zu eng.

Wenn noch kein Trainer verknüpft ist, kann der Trainer-Tab entweder:

- sichtbar bleiben und zu “Trainer finden/verbinden” führen, oder
- bis zur Verbindung verborgen bleiben.

Empfehlung: sichtbar lassen, sobald Trainer-Discovery eingeführt wird. Vor Discovery kann er verborgen bleiben.

---

## Screen-Verantwortlichkeiten

### Home

Home beantwortet: “Was mache ich heute?”

Enthält:

- aktueller Trainingsstatus
- Start Training CTA
- kompakter Fortschritt
- wichtige heutige Hinweise

Nicht enthalten:

- Profileinstellungen
- Trainer-Verknüpfung
- Community-Feed
- lange Journal-Historie

### Community

Community beantwortet: “Welche Erfahrungen teilen andere zu meinem Paket?”

Enthält:

- Pinnwand-Feed pro Paket
- Beiträge aus freiwillig geteilten Journal-Einträgen
- Leerer Zustand, wenn noch keine Beiträge oder kein passendes Paket

Nicht enthalten:

- freier Gruppenchat
- Nutzer-DMs
- Video-Calls
- technische Channel-Sprache

### Trainer

Trainer beantwortet: “Wie bin ich mit meinem Trainer verbunden?”

Für Nutzer:

- aktueller Trainer
- Direct Chat
- Termine/Terminvorschläge
- Video-Call-Anfrage oder eingehender Call
- Trainer wechseln oder später Trainer finden

Für Trainer:

- Trainer-Dashboard
- Klientenliste
- offene Anfragen
- Termine

Für Admins:

- Admin-Panel sollte nicht im normalen Nutzerfluss auftauchen, sondern über Profil oder separate Admin-Verknüpfung erreichbar sein.

### Profil

Profil beantwortet: “Wer bin ich in dieser App und was gehört zu meinem Konto?”

Enthält:

- E-Mail / Account-Zusammenfassung
- Anzeigename
- Journal
- Trainerstatus als kurze Übersicht
- Account-Verwaltung
- Zugang zu Settings

Account-Verwaltung:

- Passwort ändern
- Abmelden
- Account löschen

---

## Settings-Zielbild

Settings beantwortet nur: “Wie soll sich die App für mich verhalten?”

Empfohlene Struktur:

### Training

- Trainingsmodus: Tutorial / Routine
- Feedback: Still / Haptisch / Sprachhinweise
- Wochenziel

### Erinnerungen

- Erinnerungen an/aus
- Zeitfenster

### Darstellung

- Sprache
- Theme

### Erweitert

Nur einklappbar oder sehr weit unten:

- Sync-Status
- Manuell synchronisieren
- App-Version
- Diagnose/Support-Info

Nicht mehr in Settings:

- Trainer verbinden/wechseln
- Trainer werden
- Admin Panel
- Trainerbereich
- Passwort ändern
- Abmelden
- Account löschen
- Zurück zu Moro

---

## Wohin mit den entfernten Settings-Punkten?

| Aktueller Punkt | Neuer Ort |
|---|---|
| Trainer verbinden/wechseln | Trainer-Tab |
| Trainer werden | Profil → “Beruflicher Zugang” oder später separater Onboarding-Flow |
| Trainerbereich | Trainer-Tab, wenn `role = trainer` |
| Admin Panel | Profil → “Admin” nur für Admins |
| Passwort ändern | Profil → Account |
| Abmelden | Profil → Account |
| Account löschen | Profil → Account → destruktiver Unterpunkt |
| Zurück zu Moro | Nicht dauerhaft sichtbar; nur Support-/Recovery-Flow oder kontextuelle Aktion |
| Sync-Status | Settings → Erweitert |
| Dev Tools | Nur Development Build, nicht regulär sichtbar |

---

## Trainer-Tab Detail

Der Trainer-Tab sollte langfristig rollenabhängig sein.

### Nutzer ohne Trainer

- CTA: Trainer verbinden
- später CTA: Trainer in der Nähe finden
- kurzer Status, warum Trainer-Verbindung hilfreich ist

### Nutzer mit Trainer

- Trainerkarte mit Name/Status
- Chat öffnen
- Terminübersicht
- Video-Call anfragen
- Trainer wechseln

### Trainer

- Klientenliste
- offene Anfragen
- Termine
- eigener Verifizierungs-/Profilstatus

### Admin

Admin bleibt nicht primär im Trainer-Tab, außer Admins sind zugleich operativ als Trainer-Reviewer unterwegs. Für Phase 1 reicht Profil → Admin Panel.

---

## Empfohlene Umsetzungsreihenfolge

1. Settings konzeptionell auf vier Sektionen reduzieren: Training, Erinnerungen, Darstellung, Erweitert.
2. Account-Aktionen nach Profil verschieben.
3. Trainer-Verknüpfung aus Settings in einen Trainer-Bereich verschieben.
4. AppShell entscheiden: 3 Tabs jetzt, 4 Tabs mit Trainer sobald Discovery/Trainer-Zentrale da ist.
5. Community-Screen sprachlich von “Kanal” auf “Pinnwand/Erfahrungen” umstellen.
6. DM/Direct Chat unter Trainer statt als separater “Nachrichten”-Gedanke führen.
7. “Sonderfälle” wie Zurück zu Moro aus der sichtbaren Settings-Liste entfernen.

---

## Deferred Enterprise Hardening

Diese Punkte sind für deutschlandweite Skalierung relevant, aber nicht nötig, um die App jetzt aufzuräumen:

| Thema | Spätere Maßnahme |
|---|---|
| Rollen-Navigation | Dynamische Arbeitsbereiche für Nutzer, Trainer, Admin, Support |
| Support-Modus | Diagnosepaket, Sync-Status, Fehlerlogs, nur auf Anfrage sichtbar |
| Admin-Konsole | Eigene Admin-Navigation statt Versteck in Settings |
| Feature Flags | Saubere Sichtbarkeit neuer Bereiche pro Rolle/Phase |
| Analytics | Welche Tabs werden genutzt, wo brechen Nutzer ab, welche Settings werden gebraucht |
| Onboarding | Rollen- und Trainerstatus gezielt erklären statt in Settings verstecken |

---

## Produktentscheidung

Settings wird bewusst kein Sammelbecken mehr. Alles, was ein Nutzer selten oder mit hoher Tragweite macht, wandert in den passenden Kontext: Account ins Profil, Trainer in den Trainer-Bereich, technische Diagnose in “Erweitert”, Sonderfälle in Support-/Recovery-Flows.
