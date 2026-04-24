# Trainer Discovery — Design Spec
**Datum:** 2026-04-24  
**Status:** Approved  
**Projekt:** CoreJourney (Flutter + Supabase)

---

## Überblick

Trainer, die im CoreJourney-System registriert sind, können ihren Standort hinterlegen. Nutzer der App können Trainer in ihrer Umgebung über eine kartenbasierte Suche finden, eine Kontaktanfrage senden und sich mit ihnen verbinden. Die gesamte Kommunikation — von der Trainer-Prüfung bis zur laufenden Trainer-Nutzer-Beziehung — läuft innerhalb der App.

---

## Kernentscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Trainer-Registrierung | Hybrid: Self-service + Admin-Freigabe | Qualitätskontrolle ohne manuelle Dateneingabe |
| Geo-Technologie | PostGIS `geography(POINT, 4326)` + `ST_DWithin` | Native Supabase-Unterstützung, GIST-Index, skaliert auf 100k+ Einträge |
| Suchfilter | Radius-only | Einfach, fokussiert — erweiterbar in späteren Phasen |
| Kontaktaufnahme | Anfrage-Flow (pending → active relationship) | Kontrolle für Trainer, kein Spam, Terminvorschlag integrierbar |
| Kommunikation | Geschlossenes In-App-System | Alles dokumentiert, kein externer Kanal nötig |
| Einstiegspunkt | Dedizierter Tab + Onboarding-Nudge | Maximale Auffindbarkeit |

---

## Datenbankschema

### Neue Tabelle: `trainer_profiles`

Steht 1:1 zu `profiles` (wo `role = 'trainer'`). Bestehende Tabellen bleiben unverändert.

```sql
CREATE TABLE trainer_profiles (
  -- Identität
  id              uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Öffentliche Felder (sichtbar für alle authentifizierten Nutzer)
  display_name    text NOT NULL,
  bio             text,
  photo_url       text,
  
  -- Standort (PostGIS)
  location        geography(POINT, 4326),
  location_updated_at timestamptz,
  
  -- Approval-Status
  status          text NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'active', 'suspended')),
  approved_at     timestamptz,
  approved_by     uuid REFERENCES profiles(id),
  submitted_at    timestamptz NOT NULL DEFAULT now(),
  
  -- Admin-only Kontaktdaten (RLS: nur role='admin' liest diese Felder)
  contact_email   text NOT NULL,
  contact_phone   text,
  admin_notes     text,
  
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Räumlicher Index für ST_DWithin Performance
CREATE INDEX idx_trainer_profiles_location
  ON trainer_profiles USING GIST (location);

CREATE INDEX idx_trainer_profiles_status
  ON trainer_profiles (status);
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
  latitude     float8,
  longitude    float8
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    ROUND((ST_Distance(
      tp.location,
      ST_MakePoint(lng, lat)::geography
    ) / 1000.0)::numeric, 1)::float8 AS distance_km,
    ST_Y(tp.location::geometry) AS latitude,
    ST_X(tp.location::geometry) AS longitude
  FROM trainer_profiles tp
  WHERE
    tp.status = 'active'
    AND tp.location IS NOT NULL
    AND ST_DWithin(
      tp.location,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC;
$$;
```

Die Funktion gibt **niemals** `contact_email`, `contact_phone` oder `admin_notes` zurück.

### RLS Policies

```sql
ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;

-- Authentifizierte Nutzer sehen nur aktive Trainer (öffentliche Felder via View oder RPC)
-- Trainer sehen ihr eigenes Profil vollständig
CREATE POLICY "Trainer sees own profile"
  ON trainer_profiles FOR ALL
  USING (auth.uid() = id);

-- Admins sehen alle Profile inkl. Kontaktdaten
CREATE POLICY "Admins see all profiles"
  ON trainer_profiles FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### Schema-Erweiterung: `chat_channels`

Minimale Erweiterung des bestehenden Chat-Systems:

```sql
-- Neuer Channel-Typ
ALTER TABLE chat_channels
  DROP CONSTRAINT IF EXISTS chat_channels_type_check;
ALTER TABLE chat_channels
  ADD CONSTRAINT chat_channels_type_check
  CHECK (type IN ('direct', 'community', 'admin_review'));

-- Verknüpfung zum Trainer-Profil (nur bei admin_review gesetzt)
ALTER TABLE chat_channels
  ADD COLUMN IF NOT EXISTS trainer_profile_id uuid REFERENCES trainer_profiles(id);
```

---

## Feature-Flows

### ① Trainer — Registrierung & Standort

1. Nutzer registriert sich mit `role = 'trainer'`
2. App leitet zu `TrainerProfileSetupScreen` — Felder: Display Name, Bio, Foto, E-Mail (Pflicht), Telefon (optional)
3. Trainer pinnt Standort auf interaktiver Karte (`TrainerLocationPickerWidget`)
4. Profil wird gespeichert mit `status = 'pending'`
5. System erstellt automatisch einen `admin_review`-Kanal und fügt alle User mit `role = 'admin'` als Mitglieder hinzu
6. Trainer sieht Wartescreen mit Chat-Zugang zum Admin

### ② Admin — Prüfung & Freigabe

1. Admin sieht in `AdminTrainerReviewScreen` alle Trainer mit `status = 'pending'`
2. Pro Eintrag: Name, Standort auf Mini-Karte, Bio, Foto, `contact_email`, `contact_phone`, `submitted_at`
3. Admin kann über den `admin_review`-Kanal direkt mit dem Trainer chatten (Rückfragen, Klärungen)
4. Admin klickt „Freigeben" → `status = 'active'`, `approved_at`, `approved_by` gesetzt, Kanal archiviert
5. Trainer erhält Push-Notification: „Dein Profil wurde freigegeben"
6. Admin kann alternativ „Suspend" → `status = 'suspended'`

### ③ Nutzer — Trainer finden

**Einstieg A — Dedizierter Tab:**
- `TrainerDiscoveryScreen` öffnet sich
- App fordert Standort-Permission (einmalig, mit Erklärung)
- RPC `find_trainers_nearby(lat, lng, radius_km)` wird aufgerufen
- Ergebnis: Karte mit Pins + scrollbare Liste, sortiert nach Distanz
- Radius-Slider (Standard: 25km, Range: 5–100km)

**Einstieg B — Onboarding-Nudge:**
- Nach Assessment-Abschluss erscheint `TrainerOnboardingNudgeScreen`
- „Gibt es Trainer in deiner Nähe? Schau nach." — CTA öffnet `TrainerDiscoveryScreen`
- Nutzer kann überspringen

### ④ Nutzer → Trainer: Anfrage

1. Nutzer tippt auf Trainer-Pin oder Listen-Eintrag → `TrainerPublicProfileScreen`
2. Zeigt: Foto, Name, Bio, Distanz (z.B. „8,3 km entfernt")
3. Button „Anfrage senden" → erstellt `trainer_client_relationships` mit `status = 'pending'`
4. Trainer erhält Push: „Neue Verbindungsanfrage von [Name]"

### ⑤ Trainer → Nutzer: Antwort

1. Trainer öffnet Anfrage-Screen, sieht Nutzer-Profil (Fortschritt, aktuelles Paket)
2. „Annehmen" → `status = 'active'`, optional direkt einen Terminvorschlag (`Appointment`) mitsenden
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
  final double? latitude;
  final double? longitude;
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
- `contact_email` / `contact_phone` sind nur über direkte Tabellen-Queries mit `role = 'admin'` lesbar
- Ein Nutzer kann nur eine offene Anfrage pro Trainer haben (bestehender `UNIQUE(trainer_id, client_id)` Constraint in `trainer_client_relationships`)
- `admin_review`-Kanäle sind für normale Nutzer via RLS nicht sichtbar

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

## Was bleibt unverändert

- `profiles` — `role = 'trainer'` Logik bleibt
- `trainer_client_relationships` — vollständig wiederverwendet
- `ChannelType.direct` — unverändert für Trainer↔Nutzer nach Verbindung
- `feature_flags.trainer_accounts_enabled` — steuert weiterhin die gesamte Feature-Sichtbarkeit
