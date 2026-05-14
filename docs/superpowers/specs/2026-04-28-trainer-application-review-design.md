# Trainer Application & Verification — Design Spec
**Datum:** 2026-04-28
**Status:** Draft — supersedes the trainer onboarding parts of `2026-04-24-trainer-discovery-design.md`
**Projekt:** CoreJourney (Flutter + Supabase)

---

## Überblick

Der bisherige Trainer-Network-Ansatz aktiviert Trainer zu früh: Admins generieren einen Code, Nutzer geben ihn ein, und `profiles.role = 'trainer'` wird sofort gesetzt. Das ist für CoreJourney fachlich nicht ausreichend, weil Trainer mit Kindern und Jugendlichen arbeiten können und vor einer Freischaltung ein erweitertes Führungszeugnis Stufe 2 vorzeigen müssen.

Der neue Zielprozess dreht die Reihenfolge um:

1. Eine Person bewirbt sich als Trainer-Anwärter.
2. Die Bewerbung eröffnet einen geschützten Kommunikationskanal mit den Admins.
3. Die Admins prüfen Qualifikation, Identität und das vorgezeigte erweiterte Führungszeugnis Stufe 2.
4. Es wird **nicht** gespeichert, hochgeladen oder dauerhaft abgelegt, sondern nur die erfolgte Sichtprüfung dokumentiert.
5. Erst nach erfolgreicher Prüfung erzeugt das System einen einmaligen Aktivierungscode.
6. Die Code-Aktivierung macht den Bewerber atomar zum verifizierten Trainer.

Damit wird der Code vom Einstiegspunkt zum Abschlussnachweis der Prüfung.

---

## Kernentscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Trainer werden | Bewerbung zuerst, Code zuletzt | Der Code darf nur nach abgeschlossener Prüfung existieren |
| Führungszeugnis | Nur Sichtprüfung dokumentieren, keine Speicherung | Minimiert Datenschutz- und Haftungsrisiko |
| Admin-Kommunikation | Eigener Review-Kanal je Bewerbung | Prüfung braucht nachvollziehbare Kommunikation, getrennt von Trainer-Client-Chat |
| Trainerrolle | `profiles.role = 'trainer'` erst nach Approval-Code | Keine halb-verifizierten Trainer mit Trainerrechten |
| Discovery | Nur `trainer_profiles.status = 'active'` | Öffentlich sichtbar sind ausschließlich verifizierte Trainer |
| Audit | Jede Admin-Entscheidung wird protokolliert | Enterprise-Nachvollziehbarkeit und interne Kontrolle |
| Admin-Rechte | Phase 1 über `profiles.role = 'admin'`, später Reviewer-Rollen | Schnell umsetzbar, später granular erweiterbar |

---

## Begriffe

| Begriff | Bedeutung |
|---|---|
| Practitioner | Normaler Nutzer der App |
| Trainer-Anwärter | Nutzer mit eingereichter Trainer-Bewerbung, aber ohne Trainerrechte |
| Verifizierter Trainer | Nutzer mit `profiles.role = 'trainer'` und aktivem Trainerprofil |
| Admin/Reviewer | Interne Person, die Bewerbungen prüft |
| Review-Kanal | Geschützter Chat-Kanal zwischen Bewerber und Admins zur Prüfung |
| Aktivierungscode | Einmaliger Code, der nur aus einer genehmigten Bewerbung entsteht |

---

## Ziel-Flow

### 1. Nutzer — Bewerbung starten

1. Nutzer öffnet Profil → „Trainer werden“.
2. App zeigt Voraussetzungen:
   - fachlicher Hintergrund erforderlich
   - erweitertes Führungszeugnis Stufe 2 muss im Prüfprozess vorgezeigt werden
   - keine Speicherung des Führungszeugnisses in CoreJourney
   - Prüfung kann durch Admins abgelehnt werden
3. Nutzer füllt Bewerbungsformular aus:
   - vollständiger Name
   - E-Mail
   - Telefon optional
   - Stadt/Region
   - beruflicher Hintergrund
   - kurze Motivation
   - optional öffentliche Profilangaben für später: Anzeigename, Bio, Standort
4. Backend erstellt `trainer_applications` mit `status = 'submitted'`.
5. Backend erstellt einen Review-Kanal mit dem Bewerber und Admins.
6. App leitet auf Bewerbungsstatus + Review-Kanal.

### 2. Admin — Prüfung

1. Admin öffnet Admin Panel → „Trainer-Bewerbungen“.
2. Admin sieht Bewerbungen mit Status, Alter, letzter Nachricht und Prüfstand.
3. Admin öffnet Bewerbung:
   - Bewerbungsdaten
   - Review-Kanal
   - interne Admin-Notizen
   - Checkbox/Aktion „Führungszeugnis Stufe 2 gesehen“
4. Admin kann:
   - Rückfrage senden
   - weitere Informationen anfordern
   - Führungszeugnis-Sichtprüfung markieren
   - Bewerbung ablehnen
   - Bewerbung genehmigen

### 3. Genehmigung

Genehmigung ist nur erlaubt, wenn:

- Bewerbung existiert und gehört zum Bewerber
- Status ist `submitted`, `in_review` oder `needs_more_info`
- Führungszeugnis-Sichtprüfung ist dokumentiert
- Bewerber hat noch keine aktive Trainerrolle
- öffentliche Pflichtdaten für Trainerprofil sind vollständig oder werden aus der Bewerbung ableitbar

Bei Genehmigung:

1. `trainer_applications.status = 'approved'`
2. `reviewed_by`, `reviewed_at` werden gesetzt
3. einmaliger Aktivierungscode wird erstellt
4. Code wird im Review-Kanal oder im Bewerbungsstatus angezeigt
5. Audit-Event wird geschrieben

### 4. Code-Aktivierung

Der Bewerber gibt den Code ein oder öffnet einen späteren Deep Link.

Backend prüft:

- Code existiert
- Code ist nicht verwendet
- Code ist nicht abgelaufen
- Code hängt an einer `approved` Bewerbung
- Code wird vom Bewerber der Bewerbung eingelöst

Dann atomar:

- `profiles.role = 'trainer'`
- `trainer_profiles` wird erstellt oder aktualisiert
- `trainer_profiles.status = 'active'`
- `trainer_profiles.approved_at`, `approved_by`, `submitted_at`
- `trainer_profile_private` wird erstellt/aktualisiert
- Code wird als verwendet markiert
- Audit-Event wird geschrieben

---

## Datenmodell

### Neue Tabelle: `trainer_applications`

```sql
CREATE TABLE trainer_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  city text,
  professional_background text NOT NULL,
  motivation text,

  desired_display_name text,
  desired_bio text,
  desired_location_private geography(POINT, 4326),
  desired_location_public geography(POINT, 4326),
  desired_location_precision_m int NOT NULL DEFAULT 1000,

  status text NOT NULL DEFAULT 'submitted'
    CHECK (status IN (
      'submitted',
      'in_review',
      'needs_more_info',
      'approved',
      'rejected',
      'withdrawn'
    )),

  background_check_required boolean NOT NULL DEFAULT true,
  background_check_verified_at timestamptz,
  background_check_verified_by uuid REFERENCES profiles(id),

  assigned_reviewer uuid REFERENCES profiles(id),
  reviewed_by uuid REFERENCES profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  admin_notes text,

  activation_code_id uuid,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

Empfohlene Constraints:

```sql
CREATE UNIQUE INDEX uq_trainer_applications_open_per_user
  ON trainer_applications(user_id)
  WHERE status IN ('submitted', 'in_review', 'needs_more_info');

CREATE INDEX idx_trainer_applications_status_created
  ON trainer_applications(status, created_at DESC);
```

### Aktivierungscodes

Die bestehende Tabelle `trainer_invite_codes` kann weiterverwendet, sollte aber erweitert und semantisch umbenannt werden. Technisch ist eine additive Migration risikoärmer:

```sql
ALTER TABLE trainer_invite_codes
  ADD COLUMN IF NOT EXISTS trainer_application_id uuid
    REFERENCES trainer_applications(id),
  ADD COLUMN IF NOT EXISTS purpose text NOT NULL DEFAULT 'legacy_manual'
    CHECK (purpose IN ('legacy_manual', 'trainer_application_approval'));
```

Neue Codes für Trainer dürfen nur noch mit `purpose = 'trainer_application_approval'` und `trainer_application_id IS NOT NULL` entstehen.

### Review-Kanal

Die Chat-Infrastruktur wird erweitert, nicht dupliziert:

```sql
ALTER TABLE chat_channels
  DROP CONSTRAINT IF EXISTS chk_channel_package_id;

ALTER TABLE chat_channels
  ADD COLUMN IF NOT EXISTS application_id uuid
    REFERENCES trainer_applications(id) ON DELETE CASCADE;

ALTER TABLE chat_channels
  ADD CONSTRAINT chat_channels_type_check
    CHECK (type IN ('direct', 'community', 'application_review'));

ALTER TABLE chat_channels
  ADD CONSTRAINT chk_channel_context
    CHECK (
      (type = 'community' AND package_id IS NOT NULL AND application_id IS NULL) OR
      (type = 'direct' AND package_id IS NULL AND application_id IS NULL) OR
      (type = 'application_review' AND package_id IS NULL AND application_id IS NOT NULL)
    );
```

Falls bestehende Constraints nicht so einfach ersetzt werden können, sollte eine neue Migration mit explizitem Constraint-Namen geschrieben und lokal gegen die aktuelle DB geprüft werden.

### Audit-Logs

```sql
CREATE TABLE trainer_application_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES trainer_applications(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES profiles(id),
  event_type text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

Beispiele für `event_type`:

- `application_submitted`
- `review_channel_created`
- `reviewer_assigned`
- `background_check_marked_seen`
- `status_changed`
- `activation_code_created`
- `activation_code_used`
- `application_rejected`

---

## RLS & Security

### `trainer_applications`

- Bewerber darf eigene Bewerbung lesen.
- Bewerber darf eine neue Bewerbung erstellen, solange keine offene Bewerbung existiert.
- Bewerber darf eigene Bewerbung nur in erlaubten Feldern aktualisieren und nicht den Status/Admin-Felder setzen.
- Admins dürfen alle Bewerbungen lesen und über RPCs bearbeiten.
- Direkte Admin-Feld-Updates aus dem Client sollten vermieden werden; Statuswechsel laufen über SECURITY DEFINER RPCs.

### Review-Kanal

- Bewerber sieht nur den eigenen Review-Kanal.
- Admins/Reviewer sehen Review-Kanäle, in denen sie Mitglied sind.
- Channel-Erstellung läuft ausschließlich über RPC.
- Keine öffentliche Suche nach Review-Kanälen.

### Führungszeugnis

CoreJourney speichert kein Führungszeugnis und keine Kopie.

Gespeichert wird nur:

- Zeitpunkt der Sichtprüfung
- prüfender Admin
- optional ein kurzer interner Vermerk ohne Dokumentinhalt

Admin-UI-Texte müssen klar formulieren: „Vorgezeigt und geprüft“, nicht „hochladen“ oder „speichern“.

---

## RPCs / Edge Functions

### Neue RPCs

| RPC | Zweck |
|---|---|
| `submit_trainer_application(...)` | Bewerbung erstellen, Review-Kanal erstellen, Audit schreiben |
| `get_own_trainer_application()` | Status + Kanal für Bewerber anzeigen |
| `get_trainer_applications_for_review()` | Admin-Liste |
| `mark_background_check_seen(application_id)` | Sichtprüfung dokumentieren |
| `set_trainer_application_status(application_id, status, reason)` | `needs_more_info`, `rejected`, `in_review` |
| `approve_trainer_application(application_id)` | Bewerbung genehmigen und Aktivierungscode erzeugen |

### Bestehende Edge Functions ändern

| Function | Änderung |
|---|---|
| `create-trainer-code` | Nicht mehr frei verwendbar; nur noch intern aus `approve_trainer_application` oder mit `application_id` |
| `activate-trainer` | Muss genehmigte Bewerbung prüfen und Trainerprofil atomar aktivieren |

Die robusteste Variante ist, die Code-Erzeugung komplett in eine SQL-RPC zu ziehen. Dann muss `create-trainer-code` entweder entfernt oder nur noch als Admin-Wrapper um `approve_trainer_application` verwendet werden.

---

## Flutter UX

### Neue Screens

| Screen | Zweck |
|---|---|
| `TrainerApplicationIntroScreen` | Voraussetzungen und Datenschutz erklären |
| `TrainerApplicationFormScreen` | Bewerbung erfassen |
| `TrainerApplicationStatusScreen` | Status, nächste Schritte, Review-Kanal |
| `AdminTrainerApplicationsScreen` | Admin-Liste aller Bewerbungen |
| `AdminTrainerApplicationDetailScreen` | Detail, Prüfschritte, Review-Kanal, Aktionen |

### Bestehende Screens umbauen

| Datei | Änderung |
|---|---|
| `profile_screen.dart` | „Trainer werden“ öffnet Bewerbung, nicht Code-Dialog |
| `trainer_profile_setup_screen.dart` | Ersetzen/umbenennen in Bewerbungsformular |
| `trainer_profile_pending_screen.dart` | Ersetzen/umbenennen in Bewerbungsstatus |
| `admin_panel_screen.dart` | Tab „Trainer-Codes“ entfernen oder Legacy; neuer Tab „Trainer-Bewerbungen“ |
| `trainer_discovery_screen.dart` | Bleibt; zeigt nur aktive Trainer |
| `trainer_requests_screen.dart` | Bleibt für Client-Anfragen an aktive Trainer, nicht für Bewerbungen |

### Navigation

Neue Routen:

- `/trainer/apply`
- `/trainer/application`
- `/trainer/application/status`
- `/admin/trainer-applications`
- `/admin/trainer-applications/:applicationId`

Bestehende Routen:

- `/trainer/profile-setup` wird Legacy oder Redirect zu `/trainer/apply`
- `/trainer/profile-pending` wird Legacy oder Redirect zu `/trainer/application/status`

---

## Aktueller Stand: Was Bleibt, Was Wird Ersetzt

### Behalten

- `trainer_profiles`
- `trainer_profile_private`
- PostGIS/Standort-Jitter
- `find_trainers_nearby`
- `send_discovery_request`
- `respond_discovery_request`
- Discovery-Map/List-UX
- Trainer-Client-Beziehung und Trainerwechsel-Logik

### Ersetzen

- Trainer-Code als freier Einstieg
- Profil-Setup als erste Trainer-Verifizierung
- Admin-Review direkt auf `trainer_profiles`
- `pendingTrainersProvider` als Bewerbungs-Review
- `admin_approve_trainer` als Primärfreigabe

### Löschen oder Deaktivieren

- Freier FAB „Code generieren“ im Admin Panel
- Primärer Aktivierungscode-Dialog unter „Trainer werden“
- Beliebige Admin-Code-Erzeugung ohne Bewerbungsbezug

Legacy-Codes können für Dev/Test vorübergehend bleiben, müssen aber in Production deaktiviert oder auf Admin-Superuser beschränkt werden.

---

## Migration Strategy

### Phase 1: Additive Basis

- `trainer_applications` hinzufügen
- Audit-Tabelle hinzufügen
- `trainer_invite_codes` um `trainer_application_id` und `purpose` erweitern
- Chat-Kanäle um `application_review` erweitern
- neue RPCs erstellen
- keine bestehenden Flows löschen

### Phase 2: UI Umschalten

- „Trainer werden“ öffnet Bewerbung
- Admin Panel zeigt Bewerbungen statt freier Code-Erzeugung
- Bewerbungsstatus zeigt Review-Kanal
- Code-Eingabe nur noch für genehmigte Bewerber erreichbar

### Phase 3: Activation Hardening

- `activate-trainer` prüft zwingend genehmigte Bewerbung
- `create-trainer-code` wird gesperrt oder nur noch intern verwendet
- `profiles.role = trainer` wird nur noch aus Approval-Code gesetzt
- `trainer_profiles.status = active` wird atomar beim Code-Use gesetzt

### Phase 4: Cleanup

- Legacy Trainer-Code-UI entfernen
- alte `get_pending_trainers`/`admin_approve_trainer`-UI entfernen
- alte Routes redirecten oder löschen
- Tests und QA-Matrix aktualisieren

---

## Acceptance Criteria

- Ein normaler Nutzer kann keinen Trainer-Code mehr als ersten Schritt eingeben.
- Ein Bewerber kann eine Trainer-Bewerbung einreichen.
- Nach Einreichung existiert ein Review-Kanal zwischen Bewerber und Admins.
- Admins können im Admin Panel Bewerbungen prüfen.
- Admins können die Sichtprüfung des erweiterten Führungszeugnisses Stufe 2 markieren.
- Ohne dokumentierte Sichtprüfung kann keine Bewerbung genehmigt werden.
- Nach Genehmigung wird genau ein Aktivierungscode erzeugt.
- Der Aktivierungscode kann nur vom Bewerber der genehmigten Bewerbung genutzt werden.
- Code-Nutzung setzt Rolle und Trainerprofil atomar.
- Nur aktive, verifizierte Trainer erscheinen in Discovery.
- Führungszeugnis-Dateien werden nirgends hochgeladen oder gespeichert.
- Audit-Events existieren für Einreichung, Prüfschritte, Genehmigung, Code-Erzeugung und Code-Nutzung.

---

## Offene Entscheidungen

1. Werden alle Admins automatisch Mitglied jedes Review-Kanals oder nur zugewiesene Reviewer?
2. Soll ein Bewerber vor Genehmigung bereits öffentliche Profilfelder und Standort erfassen oder erst nach Code-Aktivierung?
3. Wie lange ist ein Approval-Code gültig? Empfehlung: 14 Tage.
4. Darf eine abgelehnte Bewerbung erneut eingereicht werden? Empfehlung: ja, aber nur nachdem alte Bewerbung final ist.
5. Braucht es später Uploads für andere Nachweise? Empfehlung: nicht für Phase 1; wenn nötig, mit eigener Retention-Policy.
