# Trainer Discovery — Design Spec
**Datum:** 2026-04-24
**Status:** Partially superseded — Discovery remains valid; trainer onboarding/review is superseded by `2026-04-28-trainer-application-review-design.md`
**Projekt:** CoreJourney (Flutter + Supabase)

---

## Überblick

Trainer, die im CoreJourney-System registriert sind, können ihren Standort hinterlegen. Nutzer der App können Trainer in ihrer Umgebung über eine kartenbasierte Suche finden, eine Kontaktanfrage senden und sich mit ihnen verbinden. Die Discovery ist nur für authentifizierte Nutzer sichtbar und zeigt privacy-safe, ungefähre Pins statt exakter Privatadressen. Die Discovery- und Standortentscheidungen in diesem Dokument bleiben gültig.

Der ursprüngliche Trainer-Registrierungs- und Admin-Freigabe-Teil dieses Dokuments ist ersetzt durch `docs/superpowers/specs/2026-04-28-trainer-application-review-design.md`. Trainer werden nicht mehr code-first aktiviert, sondern bewerben sich zuerst, eröffnen dadurch einen Admin-Review-Kanal und erhalten erst nach Prüfung einschließlich Sichtprüfung des erweiterten Führungszeugnisses Stufe 2 einen einmaligen Aktivierungscode.

---

## Kernentscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Trainer-Registrierung | Hybrid: Self-service + Admin-Freigabe | Qualitätskontrolle ohne manuelle Dateneingabe |
| Geo-Technologie | PostGIS `geography(POINT, 4326)` + `ST_DWithin`, öffentlich nur approximierte Pins | Native Supabase-Unterstützung, GIST-Index, skalierbar, privacy-safe |
| Suchfilter | Radius-only | Einfach, fokussiert — erweiterbar in späteren Phasen |
| Kontaktaufnahme | Anfrage-Flow; mehrere parallele Anfragen erlaubt | Nutzer können mehrere passende Trainer kontaktieren; Trainer behalten Kontrolle |
| Trainer-Verifizierung | Status + sichtbares Verifiziert-Badge, kein Admin-Review-Chat | Weniger Chat-Komplexität, klare Nutzeranzeige |
| Admin-Modell | Mehrere Admins über `profiles.role = 'admin'` | Organisatorisch simpel, später auf Review-Rollen erweiterbar |
| Einstiegspunkt | Dedizierter Tab für eingeloggte Nutzer + Onboarding-Nudge | Maximale Auffindbarkeit ohne öffentliche Trainerliste |

---

## Datenbankschema

### Neue Tabelle: `trainer_profiles`

Steht 1:1 zu `profiles` (wo `role = 'trainer'`). Öffentliche Discovery-Daten und private Kontakt-/Review-Daten werden getrennt, weil Supabase RLS zeilenbasiert ist und keine verlässliche Spalten-Privacy innerhalb derselben Tabelle bietet.

```sql
CREATE TABLE trainer_profiles (
  -- Identität
  id              uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,

  -- Öffentliche Felder (sichtbar für alle authentifizierten Nutzer)
  display_name    text NOT NULL,
  bio             text,
  photo_url       text,

  -- Standort (PostGIS)
  -- location_private: exakter Trainer-Standort, nur Trainer selbst und Admins.
  -- location_public: privacy-safe approximierter Karten-Pin, sichtbar nur über RPC/View.
  location_private geography(POINT, 4326),
  location_public  geography(POINT, 4326),
  location_precision_m int NOT NULL DEFAULT 1000,
  location_updated_at timestamptz,

  -- Approval-Status
  status          text NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'active', 'suspended')),
  approved_at     timestamptz,
  approved_by     uuid REFERENCES profiles(id),
  submitted_at    timestamptz NOT NULL DEFAULT now(),

  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Räumlicher Index für ST_DWithin Performance
CREATE INDEX idx_trainer_profiles_location
  ON trainer_profiles USING GIST (location_private);

CREATE INDEX idx_trainer_profiles_status
  ON trainer_profiles (status);
```

### Neue Tabelle: `trainer_profile_private`

Private Kontaktdaten und interne Review-Notizen werden separat gespeichert. Trainer sehen ihre eigenen Kontaktdaten, Admins sehen alle privaten Felder.

```sql
CREATE TABLE trainer_profile_private (
  trainer_id     uuid PRIMARY KEY REFERENCES trainer_profiles(id) ON DELETE CASCADE,
  contact_email  text NOT NULL,
  contact_phone  text,
  admin_notes    text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
```

### PostGIS Extension

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### RPC: `find_trainers_nearby`

```sql
CREATE OR REPLACE FUNCTION find_trainers_nearby(
  lat      float8,
  lng      float8,
  radius_km float8 DEFAULT 25
)
RETURNS TABLE (
  id           uuid,
  display_name text,
  bio          text,
  photo_url    text,
  distance_km  float8,
  public_latitude  float8,
  public_longitude float8,
  verified     boolean
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    ROUND((ST_Distance(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography
    ) / 1000.0)::numeric, 0)::float8 AS distance_km,
    ST_Y(tp.location_public::geometry) AS public_latitude,
    ST_X(tp.location_public::geometry) AS public_longitude,
    (tp.status = 'active') AS verified
  FROM trainer_profiles tp
  WHERE
    auth.uid() IS NOT NULL
    AND lat BETWEEN -90 AND 90
    AND lng BETWEEN -180 AND 180
    AND radius_km BETWEEN 1 AND 100
    AND tp.status = 'active'
    AND tp.location_private IS NOT NULL
    AND tp.location_public IS NOT NULL
    AND ST_DWithin(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC;
$$;
```

Die Funktion gibt **niemals** `contact_email`, `contact_phone`, `admin_notes` oder `location_private` zurück. `distance_km` wird gerundet und Kartenpins nutzen `location_public`, damit Nutzer keine exakte Adresse rekonstruieren.

### Standort-Privacy

- Trainer setzen ihren Standort exakt, damit Radius-Suche korrekt funktioniert.
- Öffentlich zurückgegeben wird nur ein approximierter Pin (`location_public`), z.B. auf ca. 1km Genauigkeit.
- `location_public` wird serverseitig berechnet, nicht vom Client geliefert. Dadurch kann der Client den Privacy-Schutz nicht umgehen.
- Bei Standortänderung darf der Trainer den Standort selbst aktualisieren. Die Verifizierung bleibt aktiv, aber `location_updated_at` wird gesetzt und Admins sehen die Änderung in einer Review-/Audit-Liste.
- Wenn ein Standortwechsel auffällig ist (z.B. anderes Land/Bundesland), kann die App später automatisch eine erneute Prüfung verlangen. Für Phase 1 reicht Admin-Sichtbarkeit.

### RLS Policies

```sql
ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;

-- Authentifizierte Nutzer sehen aktive Trainer nur über RPC/View.
-- Trainer lesen ihr eigenes Profil vollständig, dürfen Statusfelder aber nicht direkt ändern.
CREATE POLICY "Trainer reads own profile"
  ON trainer_profiles FOR SELECT
  USING (auth.uid() = id);

-- Admins sehen und bearbeiten alle Trainerprofile inkl. Status.
CREATE POLICY "Admins manage all trainer profiles"
  ON trainer_profiles FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Trainer-Profilanlage und Standortänderung laufen über SECURITY DEFINER RPCs,
-- damit status/approved_at/approved_by nicht clientseitig manipuliert werden.

ALTER TABLE trainer_profile_private ENABLE ROW LEVEL SECURITY;

-- Trainer sehen ihre eigenen privaten Profildaten
CREATE POLICY "Trainer sees own private trainer profile"
  ON trainer_profile_private FOR SELECT
  USING (auth.uid() = trainer_id);

-- Admins sehen und bearbeiten alle privaten Profildaten
CREATE POLICY "Admins manage private trainer profiles"
  ON trainer_profile_private FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### Admin-Rollen

Mehrere Personen können Trainer verifizieren. In Phase 1 reicht `profiles.role = 'admin'`; damit können beliebig viele Admin-Accounts existieren. Für feinere Rechte kann später eine Tabelle `admin_permissions` ergänzt werden.

```sql
-- Phase 1: Admin-Berechtigung über profiles.role = 'admin'
-- Mindestens zwei Admin-Accounts werden operativ angelegt.
```

### Bestehendes Invite-System

Das bestehende Invite-Code-System bleibt erhalten, aber Discovery ergänzt es:

- Invite-Code: trainer-initiiertes Verbinden, z.B. bestehender Offline-Kontakt.
- Discovery-Anfrage: nutzer-initiiertes Verbinden mit gefundenem Trainer.
- Beide Wege landen in `trainer_client_relationships`.
- Ein Nutzer darf mehrere `pending`-Anfragen an verschiedene Trainer haben.
- Ein Nutzer sollte in Phase 1 nur eine `active` Trainer-Beziehung gleichzeitig haben, passend zur aktuellen App-Logik. Wenn ein neuer Trainer angenommen wird, wird eine bestehende aktive Beziehung atomar deaktiviert.

Empfohlene Constraint-Logik:

```sql
-- Eine offene Anfrage pro Trainer-Nutzer-Paar.
CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_pending_pair
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'pending' AND client_id IS NOT NULL;

-- Eine aktive Beziehung pro Trainer-Nutzer-Paar.
CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_active_pair
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'active';
```

Die Annahme einer Discovery-Anfrage sollte über eine RPC laufen, nicht direkt aus Flutter. Diese RPC deaktiviert bestehende aktive Beziehungen desselben Nutzers, aktiviert die gewählte Beziehung und erstellt den `direct`-Chat-Channel atomar.

---

## Feature-Flows

### ① Trainer — Registrierung & Standort

1. Nutzer registriert sich mit `role = 'trainer'`
2. App leitet zu `TrainerProfileSetupScreen` — Felder: Display Name, Bio, Foto, E-Mail (Pflicht), Telefon (optional)
3. Trainer pinnt Standort auf interaktiver Karte (`TrainerLocationPickerWidget`)
4. Profil wird gespeichert mit `status = 'pending'`
5. Trainer sieht Wartescreen: „Profil wird geprüft"
6. Admins sehen den neuen Antrag in der Review-Übersicht

### ② Admin — Prüfung & Freigabe

1. Admin sieht in `AdminTrainerReviewScreen` alle Trainer mit `status = 'pending'`
2. Pro Eintrag: Name, Standort auf Mini-Karte, Bio, Foto, `contact_email`, `contact_phone`, `submitted_at`
3. Admin klickt „Verifizieren" → `status = 'active'`, `approved_at`, `approved_by` gesetzt
4. Trainer erhält Push-Notification: „Dein Profil wurde verifiziert"
5. Admin kann alternativ „Ablehnen/Suspendieren" → `status = 'suspended'`
6. Öffentliche Trainerprofile zeigen ein Verifiziert-Badge für `status = 'active'`

### ③ Nutzer — Trainer finden

**Einstieg A — Dedizierter Tab (empfohlen):**
- `TrainerDiscoveryScreen` öffnet sich
- App fordert Standort-Permission (einmalig, mit Erklärung)
- RPC `find_trainers_nearby(lat, lng, radius_km)` wird aufgerufen
- Ergebnis: Karte mit privacy-safe approximierten Pins + scrollbare Liste, sortiert nach Distanz
- Radius-Slider (Standard: 25km, Range: 5–100km)
- Wenn Standort-Permission abgelehnt wird: manuelle Ortssuche oder PLZ/Stadt als Fallback in einer späteren Phase

**Einstieg B — Onboarding-Nudge:**
- Nach Assessment-Abschluss erscheint `TrainerOnboardingNudgeScreen`
- „Gibt es Trainer in deiner Nähe? Schau nach." — CTA öffnet `TrainerDiscoveryScreen`
- Nutzer kann überspringen

Discovery ist kein öffentlicher Marketing-Index vor Login. Sie bleibt hinter Auth, damit Standortabfragen, Anfrage-Spam und Trainerdaten besser kontrolliert werden können.

### ④ Nutzer → Trainer: Anfrage

1. Nutzer tippt auf Trainer-Pin oder Listen-Eintrag → `TrainerPublicProfileScreen`
2. Zeigt: Foto, Name, Bio, Distanz (z.B. „8,3 km entfernt")
3. Button „Anfrage senden" → erstellt `trainer_client_relationships` mit `status = 'pending'`
4. Trainer erhält Push: „Neue Verbindungsanfrage von [Name]"
5. Nutzer kann parallel weitere Trainer anfragen

### ⑤ Trainer → Nutzer: Antwort

1. Trainer öffnet Anfrage-Screen, sieht Nutzer-Profil (Fortschritt, aktuelles Paket)
2. „Annehmen" → `status = 'active'`, bestehende aktive Trainer-Beziehung des Nutzers wird atomar deaktiviert, optional direkt einen Terminvorschlag (`Appointment`) mitsenden
3. Bei Annahme: `ChannelType.direct`-Kanal wird erstellt → Trainer und Nutzer können sofort chatten
4. „Ablehnen" → `status = 'disconnected'`, Nutzer wird benachrichtigt

---

## Flutter-Architektur

### Neue Screens

| Screen | Zweck |
|---|---|
| `TrainerDiscoveryScreen` | Karte + Liste + Radius-Slider |
| `TrainerPublicProfileScreen` | Öffentliches Trainer-Profil + Anfrage-CTA |
| `TrainerProfileSetupScreen` | Trainer richtet sein Profil ein |
| `TrainerLocationPickerWidget` | Interaktive Karte zum Standort-Pinnen |
| `TrainerOnboardingNudgeScreen` | Post-Assessment Discovery-Empfehlung |
| `AdminTrainerReviewScreen` | Admin-Übersicht aller pending Trainer |

### Neue Domain-Modelle

```dart
// lib/features/trainer/domain/models/trainer_profile.dart
class TrainerProfile {
  final String id;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final double? distanceKm;      // nur in Suchergebnissen befüllt
  final double? publicLatitude;
  final double? publicLongitude;
  final bool verified;
  final TrainerProfileStatus status;
  final DateTime submittedAt;
  // Admin-only (nullable, nur wenn role=admin):
  final String? contactEmail;
  final String? contactPhone;
  final String? adminNotes;
}

enum TrainerProfileStatus { pending, active, suspended }
```

### Repository

```dart
// lib/features/trainer/domain/repositories/trainer_profile_repository.dart
abstract class TrainerProfileRepository {
  Future<List<TrainerProfile>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
  });
  Future<TrainerProfile> getOwnProfile();
  Future<void> createOrUpdateProfile(TrainerProfile profile);
  Future<void> updateLocation(double lat, double lng);
  // Admin:
  Future<List<TrainerProfile>> getPendingTrainers();
  Future<void> approveTrainer(String trainerId);
  Future<void> suspendTrainer(String trainerId, {String? reason});
}
```

### Packages (neu benötigt)

| Package | Zweck |
|---|---|
| `flutter_map` | Karte rendern, Pins setzen — OpenStreetMap-basiert, kein API-Key, kein Billing |
| `geolocator` | Nutzer-GPS-Position |
| `latlong2` | Koordinaten-Typen für flutter_map |

`google_maps_flutter` wäre die Alternative, erfordert aber Google Maps API Key + Billing-Setup. `flutter_map` ist für diesen Use Case ausreichend und hat keine externen Abhängigkeiten.

---

## RLS & Sicherheit

- `find_trainers_nearby()` läuft als `SECURITY DEFINER` — gibt niemals Admin-only Felder zurück
- `SECURITY DEFINER`-Funktionen setzen `search_path = public`, prüfen `auth.uid()` und begrenzen Radius/Koordinaten
- `contact_email` / `contact_phone` / `admin_notes` liegen in `trainer_profile_private`
- Exakter Standort (`location_private`) wird nie an Discovery-Clients zurückgegeben
- Ein Nutzer kann mehrere offene Anfragen an unterschiedliche Trainer haben
- Pro Trainer-Nutzer-Paar darf es maximal eine offene/aktive Anfrage geben
- Pro Nutzer sollte in Phase 1 nur eine aktive Trainer-Beziehung bestehen; Wechsel werden serverseitig atomar durchgeführt
- Kein `admin_review`-Channel; Verifizierung läuft über Statusfelder und Admin-Screen

---

## Erweiterbarkeit (Future Phases)

Das Schema ist ohne Breaking Changes erweiterbar:

| Feature | Erweiterung |
|---|---|
| Verfügbarkeitskalender (Arzt-Lib-Style) | Neue Tabelle `trainer_availability` mit Zeitfenstern |
| Spezialisierungen / Tags | Neue Tabelle `trainer_specializations` (m:n) |
| Bewertungen | Neue Tabelle `trainer_reviews` mit Score |
| Erweiterter Suchfilter | RPC-Parameter ergänzen (spezialization_id, min_rating) |

---

## Deferred Enterprise Hardening

Diese Punkte sind bewusst nicht Teil der ersten Umsetzung. Die aktuelle Discovery bleibt schlank, privacy-safe und scale-ready genug für den Start. Sobald das Trainer-Netzwerk wächst, werden folgende Themen nachgezogen:

| Thema | Spätere Maßnahme |
|---|---|
| Abuse-/Spam-Schutz | Rate Limits für Kontaktanfragen, Cooldowns nach Ablehnung, maximale offene Anfragen pro Zeitraum |
| Admin-Berechtigungen | Feineres Rollenmodell wie `owner`, `admin`, `trainer_reviewer`, `support` statt nur `profiles.role = 'admin'` |
| Audit-Logs | Tabelle für Verifizierungen, Suspendierungen, Standortänderungen und Admin-Aktionen |
| DSGVO-Betrieb | Export-/Löschprozesse, expliziter Consent für Standortveröffentlichung, Aufbewahrungsfristen |
| Karten-Infrastruktur | Kommerzieller Tile-Provider oder eigener Tile-Service statt unkontrollierter öffentlicher OSM-Tile-Nutzung |
| Standortqualität | Adresse/PLZ/Stadt-Erfassung und serverseitige Geocoding-Pipeline, öffentlich weiterhin nur approximiert |
| Ranking | Sortierung nach Kapazität, Spezialisierung, Entfernung, Antwortquote und Verfügbarkeit |
| Monitoring | Metriken für Suchanfragen, Regionen ohne Treffer, Pending-Anfragen, Annahmequote und Admin-Backlog |

Für Phase 1 bleiben nur die direkt sicherheitsrelevanten Mindestplanken verpflichtend: keine exakten öffentlichen Pins, private Felder getrennt halten, kritische Mutationen serverseitig ausführen und Discovery hinter Login betreiben.

---

## Was bleibt unverändert

- `profiles` — `role = 'trainer'` Logik bleibt
- `trainer_client_relationships` — vollständig wiederverwendet
- `ChannelType.direct` — unverändert für Trainer↔Nutzer nach Verbindung
- `chat_channels` — kein neuer `admin_review`-Typ nötig
- `feature_flags.trainer_accounts_enabled` — steuert weiterhin die gesamte Feature-Sichtbarkeit
