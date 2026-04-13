# Kommunikations-Feature Design
**Datum:** 2026-04-13
**Status:** Genehmigt

---

## Übersicht

Dieses Dokument beschreibt das Design für die Integration von Chat-, Video- und Triage-Bot-Funktionalität in CoreJourney. Ziel ist es, die Kommunikation zwischen Practitioners und Trainern sowie unter Practitioners zu ermöglichen.

### Scope

- **1:1 Chat** — Practitioner ↔ Trainer (direkt, privat)
- **Community-Channels** — offene Gruppen-Channels pro Reflex-Block
- **Video-Chat** — 1:1 (Practitioner ↔ Trainer) und Gruppen (Trainer → mehrere Klienten)
- **Triage-Bot** — erkennt häufige Fragen, leitet an FAQ oder Trainer weiter

### Nicht im Scope

- Direktnachrichten zwischen Practitioners
- Chat-Aufzeichnung oder Nachrichtenexport
- Video-Aufzeichnung
- KI-generierte Bot-Antworten (nur vorgefertigte FAQ-Texte)

---

## Architektur

Das Kommunikations-Feature baut vollständig auf dem bestehenden Supabase-Stack auf.

```
┌─────────────────────────────────────────────┐
│                Flutter App                  │
│                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ │
│  │   Chat    │ │   Video   │ │  Triage   │ │
│  │  Feature  │ │  Feature  │ │   Bot     │ │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ │
└────────┼─────────────┼─────────────┼────────┘
         │             │             │
         ▼             ▼             ▼
   Supabase RT    Agora SDK    Supabase Edge
   + PostgreSQL   (WebRTC)      Function
         │             │             │
         └─────────────┼─────────────┘
                       ▼
                  Supabase DB
                 (PostgreSQL)
```

**Chat:** Supabase Realtime abonniert PostgreSQL-Tabellen. Neue Nachrichten-Rows triggern Echtzeit-Updates im Client. Bestehende RLS-Policies werden auf neue Tabellen ausgedehnt.

**Video:** Agora übernimmt WebRTC-Signalisierung und Medien-Übertragung. Flutter-App ruft Agora-Tokens von einer Supabase Edge Function ab — das Agora-Secret bleibt ausschließlich server-seitig. Call-Metadaten landen in PostgreSQL.

**Triage-Bot:** Eine Supabase Edge Function empfängt neue Nachrichten, matched gegen eine FAQ-Tabelle, und schreibt entweder eine vorgefertigte Antwort zurück oder erstellt eine Trainer-Benachrichtigung.

**Neues Flutter-Package:**
- `agora_rtc_engine` — Video-Calls
- `supabase_flutter` bereits vorhanden — Realtime-Subscriptions ohne neue Dependency

---

## Datenmodell

### Tabelle: `chat_channels`

Definiert alle Chat-Räume.

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| id | uuid | PK | |
| type | text | not null | `'direct'` oder `'community'` |
| package_id | text | FK → reflex_packages, nullable | Nur für Community-Channels |
| created_at | timestamptz | not null, default now() | |

- Community-Channels werden automatisch erstellt wenn ein `reflex_package` angelegt wird.
- Direct-Channels werden beim Verlinken von Trainer und Klient erstellt.

---

### Tabelle: `chat_channel_members`

Zugehörigkeit von Usern zu Channels.

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| channel_id | uuid | FK → chat_channels | |
| user_id | uuid | FK → profiles | |
| role | text | not null, default 'member' | `'member'` oder `'moderator'` |
| joined_at | timestamptz | not null, default now() | |

**RLS:**
- Read: `user_id = auth.uid()` — User sieht nur eigene Mitgliedschaften
- Channel-Nachrichten lesbar wenn `user_id = auth.uid()` in `chat_channel_members` für diesen Channel

Trainer werden beim Linking automatisch als `moderator` in den Direct-Channel eingetragen und als `moderator` in alle Community-Channels, in denen der jeweilige Klient Mitglied ist. Ein Trainer mit mehreren Klienten wird nur in die Channels der eigenen Klienten eingetragen — nicht in alle Community-Channels global.

---

### Tabelle: `chat_messages`

Alle Nachrichten aller Channels.

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| id | uuid | PK | |
| channel_id | uuid | FK → chat_channels, not null | |
| sender_id | uuid | FK → profiles, not null | |
| content | text | not null | Nachrichtentext |
| is_bot_response | boolean | not null, default false | Vom Triage-Bot generiert |
| deleted_at | timestamptz | nullable | Soft-delete durch Moderator |
| created_at | timestamptz | not null, default now() | |

**RLS:**
- Read: User ist Mitglied des Channels (via `chat_channel_members`)
- Insert: `sender_id = auth.uid()` und User ist Channel-Mitglied
- Update (`deleted_at`): `role = 'moderator'` für diesen Channel oder `sender_id = auth.uid()`

Gelöschte Nachrichten (`deleted_at IS NOT NULL`) werden im Client als *"Diese Nachricht wurde entfernt"* angezeigt — kein hartes Delete.

---

### Tabelle: `video_calls`

Metadaten zu Video-Calls.

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| id | uuid | PK | |
| channel_id | uuid | FK → chat_channels, not null | Verknüpft mit Chat-Channel |
| agora_channel_name | text | not null, unique | Eindeutiger Agora-Raumname |
| started_by | uuid | FK → profiles, not null | |
| started_at | timestamptz | not null, default now() | |
| ended_at | timestamptz | nullable | null = Call läuft noch |

---

### Tabelle: `bot_faqs`

Vorgefertigte Triage-Bot-Antworten.

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| id | uuid | PK | |
| keywords | text[] | not null | Trigger-Keywords (lowercase, z.B. `['schmerz', 'pain', 'weh']`) |
| response_de | text | not null | Deutsche Antwort |
| response_en | text | not null | Englische Antwort |
| escalate_to_trainer | boolean | not null, default false | Trainer zusätzlich benachrichtigen |

---

## Chat-Feature

### Navigation

Ein "Chat"-Tab wird in die Bottom Navigation eingefügt — für alle Rollen.

```
[Training] [Fortschritt] [Chat] [Einstellungen]
```

Der Chat-Tab zeigt eine geteilte Inbox:
- **Direkt** — 1:1-Channel mit dem verlinkten Trainer
- **Community** — alle Block-Channels mit aktivem oder abgeschlossenem Enrollment

Ungelesene Nachrichten zeigen einen Badge auf dem Tab-Icon.

**Edge Case — kein verlinkter Trainer:** Wenn ein Practitioner noch keinen Trainer verlinkt hat, zeigt der "Direkt"-Bereich einen leeren Zustand mit dem Hinweis: *"Verlinke dich mit einem Trainer, um direkte Nachrichten zu nutzen."* Community-Channels sind weiterhin zugänglich.

---

### 1:1 Chat (Practitioner ↔ Trainer)

Wird beim Verlinken automatisch erstellt. Beide Seiten sehen dieselbe Konversation.

**Features:**
- Chronologische Nachrichten-Liste mit Infinite Scroll (ältere Nachrichten on demand)
- Typing Indicator via Supabase Realtime Presence
- Ungelesene-Badge auf Tab
- FCM Push-Notification bei neuer Nachricht wenn App im Hintergrund (bestehende FCM-Infrastruktur)
- Video-Call-Button oben rechts → startet 1:1 Call direkt aus Chat

---

### Community-Channels

Ein Channel pro Reflex-Block. User wird automatisch Mitglied wenn sein aktives Enrollment diesen Block hat.

- Trainer in diesem Channel = Moderator (kann Nachrichten soft-deleten)
- Kein Video-Call-Button in Community-Channels (nur 1:1)
- Gelöschte Nachrichten: `"Diese Nachricht wurde entfernt"` (kein hartes Delete)

---

### Triage-Bot

Systemuser "CoreJourney Assistent" ist in jedem Channel sichtbar.

**Ablauf nach jeder neuen Nachricht:**
1. Supabase Edge Function vergleicht Nachrichteninhalt (lowercase) mit `bot_faqs.keywords`
2. **Match gefunden:** Bot schreibt vorgefertigte Antwort in der Sprache des Users
   - `escalate_to_trainer = true`: zusätzlich FCM-Push an Trainer
3. **Kein Match:** Bot schreibt *"Ich habe deine Frage an deinen Trainer weitergeleitet."* + FCM an Trainer
4. Bot antwortet nicht auf eigene Nachrichten (`is_bot_response = true` überspringt Trigger)

---

## Video-Chat

### Token-Generierung

Agora-Secret bleibt server-seitig. Ablauf:

```
Flutter App
  → POST /functions/v1/agora-token { channel_id }
  → Edge Function prüft Channel-Mitgliedschaft via RLS
  → generiert Agora-Token mit App-Secret
  → Token zurück an App
  → agora_rtc_engine.joinChannel(token, agoraChannelName)
```

---

### Starterrechte und Call-Anfragen

**Nur Trainer dürfen Video-Calls starten** — sowohl 1:1 als auch Gruppen-Calls. Practitioners können einen Call nicht direkt initiieren, sondern nur eine Anfrage senden. Dies verhindert unkontrollierten Kostenaufbau durch häufige Calls.

**Call-Anfrage-Ablauf (Practitioner):**
1. Practitioner tippt "Call anfragen"-Button im Direct-Chat
2. Eine Systemnachricht erscheint im Chat: *"[Name] hat einen Video-Call angefragt."*
3. Trainer sieht die Anfrage im Chat und entscheidet, ob er den Call startet
4. Trainer tippt "Call starten" → normaler Call-Ablauf beginnt
5. Lehnt der Trainer ab (oder ignoriert): keine weiteren Aktionen, Anfrage bleibt als Chatnachricht sichtbar

Für Call-Anfragen wird **keine** neue Tabelle benötigt — sie sind reguläre Chatnachrichten mit `is_call_request = true`.

---

### Tabelle: `chat_messages` — Erweiterung

| Column | Type | Constraints | Beschreibung |
|---|---|---|---|
| is_call_request | boolean | not null, default false | Kennzeichnet eine Call-Anfrage vom Practitioner |

---

### 1:1 Video-Call

Gestartet ausschließlich vom Trainer per Button im Direct-Chat.

**Ablauf:**
1. Trainer tippt "Call starten"-Button (nur für Trainer sichtbar) oder antwortet auf eine Call-Anfrage
2. App erstellt `video_calls`-Row → `agora_channel_name` = `direct_{channel_id}_{timestamp}`
3. Supabase Realtime benachrichtigt den Practitioner → eingehender Call-Screen
4. Beide holen Agora-Token via Edge Function und joinen Agora-Channel
5. **Call-UI:** eigenes Video klein (PiP), Gegenüber groß, Mute-Toggle, Kamera-Toggle, Auflegen
6. Auflegen → `ended_at` gesetzt → beide verlassen Agora-Channel

**Practitioner-UI:** Kein "Call starten"-Button. Stattdessen: "Call anfragen"-Button → sendet Systemnachricht an den Trainer.

---

### Gruppen-Video

Nur Trainer können einen Gruppen-Call starten (Moderator-Rolle erforderlich). Practitioners können auch hier nur eine Anfrage per Chat-Nachricht stellen.

**Ablauf:**
1. Trainer öffnet Community-Channel → "Gruppen-Call starten"-Button (nur für Moderatoren sichtbar)
2. App erstellt `video_calls`-Row verknüpft mit Community-Channel
3. Alle Channel-Mitglieder erhalten FCM-Push: *"Dein Trainer hat einen Live-Call gestartet"*
4. Mitglieder können freiwillig beitreten solange `ended_at = null`
5. Trainer beendet Call → `ended_at` gesetzt → alle Teilnehmer werden getrennt

---

## Fehlerbehandlung & Offline-Verhalten

### Chat offline

Chat ist nicht Teil des kritischen Trainingspfads — kein Offline-Write.

- Senden nicht möglich → Eingabefeld zeigt dezenten Hinweis: *"Keine Verbindung"*
- Bereits geladene Nachrichten bleiben sichtbar (in-memory, kein Drift-Cache)
- Beim Reconnect: Supabase Realtime stellt Subscription automatisch wieder her

### Video-Call bei Verbindungsproblemen

- Agora handhabt adaptive Bitrate und Reconnect intern
- Dauerhafter Abbruch: Agora-Timeout-Event → App zeigt Fehlermeldung → zurück zum Chat
- `ended_at` wird via Edge Function gesetzt wenn Initiator disconnectet

### Moderations-Fehler

Schlägt Soft-Delete fehl (RLS-Verletzung), erhält der Trainer eine klare Fehlermeldung. Kein stilles Scheitern.

### Kamera-Permission verweigert

Audio-only-Fallback, kein harter Fehler. Kamera-Permission wird beim ersten Call-Start angefragt.

---

## Agora Kosten

- **Free Tier:** 10.000 Minuten/Monat kostenlos — für den Start ausreichend
- Kein Recording in V1 — nur Live-Stream

---

## Zusammenfassung

| Feature | Lösung |
|---|---|
| 1:1 Chat | Supabase Realtime + PostgreSQL |
| Community-Channels | Supabase Realtime, 1 Channel/Block |
| Moderation | Trainer = Moderator, Soft-Delete |
| Triage-Bot | Supabase Edge Function + FAQ-Tabelle |
| Video 1:1 | Agora, nur Trainer startet, Practitioner kann anfragen |
| Gruppen-Video | Agora, nur Trainer startet, FCM-Einladung an alle |
| Offline-Chat | Read-only, kein lokaler Cache |
| Notifications | Bestehende FCM-Infrastruktur |
| Neuer Vendor | Agora (Video) — kein weiterer |
