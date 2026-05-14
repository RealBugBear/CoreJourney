# Chat, Community & Video — Enterprise Review
**Datum:** 2026-04-25
**Status:** Draft for alignment
**Projekt:** CoreJourney (Flutter + Supabase + Agora)

---

## Überblick

Die Kommunikationsfunktionen werden in drei getrennte Produktbereiche aufgeteilt:

1. **1:1 Kommunikation** — privater Trainer-Nutzer-Chat und 1:1 Video-Call.
2. **Community-Pinnwand** — keine freie Chatgruppe, sondern ein Erfahrungsforum aus bewusst geteilten Journal-Einträgen.
3. **Keine Gruppen-Calls** — Video bleibt 1:1 zwischen Trainer und Nutzer.

Diese Trennung ist wichtig für Skalierbarkeit, Moderation, Datenschutz und Produktklarheit. Nutzer sollen nicht beliebig Direktnachrichten an andere Nutzer schreiben können.

---

## Kernentscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Direktnachrichten | Nur Trainer ↔ Nutzer | Schutz vor Spam, Übergriffigkeit und Moderationslast |
| Community | Pinnwand/Forum aus geteilten Journal-Einträgen | Erfahrungslernen ohne offenen Gruppenchat |
| Community-Beiträge | Nutzer teilen ausgewählte Journal-Einträge aktiv | Keine automatische Veröffentlichung privater Inhalte |
| Community-Kommentare | Phase 1: keine freien Kommentare | Minimiert Moderationsrisiko und toxische Dynamiken |
| Video | Phase 1: stabiler 1:1 Trainer-Nutzer-Call | Erst Basis zuverlässig machen |
| Gruppen-Video | Nicht vorgesehen | Passt fachlich nicht zum CoreJourney-Kontext |
| Moderation | Trainer/Admin kann Beiträge ausblenden | Enterprise-taugliche Mindestkontrolle |

---

## Ist-Zustand

Die Codebasis enthält bereits:

- Supabase-Tabellen für `chat_channels`, `chat_channel_members`, `chat_messages`
- Direct- und Community-Channel-Typen
- `video_calls`-Tabelle
- Agora Edge Function `agora-token`
- Flutter `VideoCallScreen`
- Chat-Inbox und Chat-Channel-Screen

Der bestehende Community-Mechanismus ist technisch noch als Chat-Channel gedacht. Produktseitig soll daraus aber eine Pinnwand werden, in der Nutzer ausgewählte Journal-Einträge teilen.

---

## Zielbild

### 1. Direct Chat

Direct Chat bleibt ein privater Kanal zwischen Trainer und Nutzer.

- Nutzer kann dem eigenen Trainer schreiben.
- Trainer kann eigenen Nutzern schreiben.
- Keine Nutzer-zu-Nutzer-DMs.
- Chat bleibt an aktive Trainer-Beziehung gebunden.
- Bei Trainerwechsel wird der alte Direct-Channel nicht gelöscht, aber für neue Nachrichten gesperrt oder archiviert.

### 2. 1:1 Video-Call

Video-Calls gehören in den Direct-Channel.

Phase-1-Ziel:

- Trainer startet Call.
- Nutzer erhält sichtbare eingehende Call-Anzeige.
- Beide können beitreten.
- Beide können auflegen.
- Call endet serverseitig sauber.
- Fehler werden sichtbar und nicht still auf leere Tokens reduziert.

Nicht Phase 1:

- Gruppen-Calls
- Aufzeichnungen
- Screensharing
- Warteschlangen
- Kalenderbasierte Video-Räume

### 3. Community-Pinnwand

Community ist kein Chat.

Ein Nutzer kann nach einer Trainingseinheit oder aus dem Journal heraus einen Eintrag bewusst teilen:

1. Nutzer schreibt Journal-Eintrag privat.
2. Nutzer tippt optional „Mit Community teilen".
3. App zeigt Vorschau und Datenschutzhinweis.
4. Nutzer bestätigt.
5. Beitrag erscheint in der Community-Pinnwand des passenden Pakets.

Beiträge enthalten in Phase 1:

- anonymisierte oder gewählte Anzeigenamen-Option
- Paket/Block-Kontext
- Datum oder relativer Zeitpunkt
- Journal-Text oder ausgewählte Reflexion
- optionale Stimmung/Trainingserfahrung, falls der Nutzer diese freigibt

Beiträge enthalten nicht:

- private Trainer-Nutzer-Nachrichten
- vollständige private Journal-Historie
- automatische Gesundheitsdaten
- Standortdaten
- direkte Kontaktmöglichkeiten zu anderen Nutzern

---

## Empfohlenes Datenmodell

Der bestehende Chat kann für Direct Chat weitergenutzt werden. Für die Community-Pinnwand sollte nicht langfristig `chat_messages` missbraucht werden, weil Pinnwand-Beiträge andere Semantik haben als Chat-Nachrichten.

### Neue Tabelle: `community_posts`

```sql
CREATE TABLE community_posts (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id      uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  package_id     text NOT NULL REFERENCES reflex_packages(id) ON DELETE CASCADE,
  journal_entry_id uuid REFERENCES journal_entries(id) ON DELETE SET NULL,
  content        text NOT NULL,
  display_mode   text NOT NULL DEFAULT 'first_name'
                 CHECK (display_mode IN ('anonymous', 'first_name')),
  status         text NOT NULL DEFAULT 'visible'
                 CHECK (status IN ('visible', 'hidden', 'removed')),
  hidden_by      uuid REFERENCES profiles(id),
  hidden_reason  text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_community_posts_package_created
  ON community_posts(package_id, created_at DESC)
  WHERE status = 'visible';

CREATE INDEX idx_community_posts_author
  ON community_posts(author_id, created_at DESC);
```

### RLS-Grundsatz

- Nutzer lesen sichtbare Beiträge nur für Pakete, in denen sie aktiv oder abgeschlossen enrolled sind.
- Nutzer erstellen Beiträge nur aus eigenen Journal-Einträgen.
- Nutzer dürfen eigene Beiträge ausblenden/entfernen.
- Trainer/Admins dürfen Beiträge ausblenden, wenn sie für den Paket-/Nutzerkontext zuständig sind.

---

## Warum Video aktuell wahrscheinlich nicht zuverlässig klappt

Die bestehende Video-Implementierung hat mehrere MVP-Bruchstellen:

- Android-Manifest enthält aktuell keine Kamera-/Mikrofon-Permissions.
- Eingehende Calls werden nur im offenen `ChatChannelScreen` erkannt.
- Es gibt keinen app-weiten Call-Listener.
- Es gibt keine Push-Benachrichtigung für Hintergrund/geschlossene App.
- Token-Fehler werden im Repository geschluckt und als leerer Dev-Token weitergeführt.
- `video_calls` erlaubt mehrere aktive Calls pro Channel, wenn kein eindeutiger Partial-Index existiert.
- Nur der Starter darf `ended_at` setzen; wenn die andere Seite auflegt, kann der Call aktiv hängen bleiben.
- Start/End laufen direkt über Tabellen-Mutationen statt über serverseitige Call-Lifecycle-RPCs.

---

## Minimaler Fix-Plan für 1:1 Video

### Phase 1 — Funktion zuverlässig bekommen

1. Android Kamera-/Mikrofon-Permissions ergänzen.
2. Token-Fallback entfernen oder nur in explizitem Dev-Modus erlauben.
3. Partial Unique Index: maximal ein aktiver Call pro Direct-Channel.
4. `start_direct_call(channel_id)` RPC: prüft Mitgliedschaft, Direct-Channel, Rolle, aktiven Call.
5. `end_call(call_id)` RPC: erlaubt beiden Channel-Mitgliedern, den Call zu beenden.
6. App-weiter Active-Call-Listener für alle Direct-Channels des Nutzers.
7. Klare UI-Zustände: lädt, klingelt, verbunden, beendet, fehlgeschlagen.

### Phase 2 — Produktreife

1. Push bei eingehendem Call.
2. Call-Timeout, wenn niemand beitritt.
3. Missed-Call-Systemnachricht im Direct Chat.
4. Debug-/Support-Metadaten: Fehlercode, Plattform, App-Version, Token-Modus.
5. Verbindungstest im Profil oder Settings-Screen.

---

## Community-Pinnwand MVP

Phase 1 soll bewusst klein bleiben:

- Post aus Journal teilen.
- Feed pro Paket anzeigen.
- Eigene Posts löschen/ausblenden.
- Trainer/Admin kann Posts ausblenden.
- Keine Kommentare.
- Keine Likes als Wachstumsmechanik; optional später einfache Reaktionen.

Das reduziert Moderationsaufwand und schützt die therapeutische/coachende Atmosphäre der App.

---

## Gruppen-Calls

Gruppen-Calls sind nicht vorgesehen.

Begründung:

- Die Community soll ein ruhiger Erfahrungsraum bleiben, kein Live-Kommunikationsraum.
- Der Kernnutzen von Video liegt in der individuellen Trainer-Nutzer-Betreuung.
- Gruppen-Calls würden Moderation, Datenschutz, Terminlogik und technische Komplexität stark erhöhen.
- Für deutschlandweite Skalierung ist ein stabiler 1:1 Call wertvoller als ein Gruppenformat.

---

## Deferred Enterprise Hardening

Diese Punkte sind wichtig für deutschlandweite Skalierung, aber nicht Voraussetzung für den ersten stabilen Release:

| Thema | Spätere Maßnahme |
|---|---|
| Moderation | Review-Queue, Melden-Funktion, Moderationsnotizen |
| Abuse-Schutz | Rate Limits für Posts, Call-Starts und Nachrichten |
| Rollenmodell | `owner`, `admin`, `trainer`, `moderator`, `support` |
| Audit-Logs | Admin-/Trainer-Aktionen an Posts, Calls und Channels protokollieren |
| Push-Infrastruktur | FCM/APNs für Calls, Nachrichten und Moderation |
| Observability | Call-Erfolgsquote, Abbruchgründe, Realtime-Latenz, Feed-Aktivität |
| Datenschutz | Export/Löschung geteilter Posts, Consent-Versionierung |
| Content Safety | Keyword-Flags, manuelle Review bei sensiblen Begriffen |

---

## Produktgrenze

Gruppen-Video bleibt außerhalb des CoreJourney-Scopes. Wenn später Live-Formate entstehen, sollten sie als neues Produktmodul neu bewertet werden und nicht aus der Community-Pinnwand heraus wachsen.
