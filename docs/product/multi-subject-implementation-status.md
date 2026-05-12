# Mehrpersonen-Training: Implementierungsstatus

Stand: 2026-05-11  
Bezug: reflex-profile-multi-subject-architecture-plan.md

---

## Überblick

Die Migration von „Account = trainierende Person" zu „Account verwaltet mehrere Trainingsprofile" ist vollständig umgesetzt. Alle 7 Schritte des Architekturplans plus die daraus entstandenen Folgearbeiten sind abgeschlossen.

---

## Datenmodell

### Neue / erweiterte Tabellen in Supabase

| Tabelle | Änderung |
|---|---|
| `reflex_subject_profiles` | Kern-Entität; `adult_self` oder `child`; `birth_date`, `age_group` |
| `reflex_profile_assessments` | `subject_profile_id`, `age_years_at_assessment`, `age_months_at_assessment`, `age_group_at_assessment` |
| `reflex_profile_trainer_shares` | Pro-Profil-Freigabe für Trainer; Widerruf via `revoked_at` |
| `appointment_subject_profiles` | Join-Tabelle: ein Termin kann 0–n Profile betreffen |
| `enrollments` | `subject_profile_id` (nullable) |
| `training_sessions` | `subject_profile_id` (nullable) |
| `progress_entries` | `subject_profile_id` (nullable) |
| `mood_checkins` | `subject_profile_id` (nullable) |
| `journal_entries` | `subject_profile_id` (nullable) |
| `completion_questionnaires` | `subject_profile_id` (nullable) |

### Migrations-Dateien (chronologisch)

```
20260510_reflex_profile_questionnaire_v1.sql       — Grundstruktur Reflexprofile
20260511_reflex_age_snapshot_and_birth_date.sql    — Alters-Snapshot auf Assessments
20260511_training_subject_profile_links.sql        — subject_profile_id auf Trainingsdaten
20260511_appointment_subject_profile_links.sql     — appointment_subject_profiles Join-Tabelle
20260511_reflex_admin_rollup_v2.sql                — Admin-RPC nutzt age_group_at_assessment
20260511_subject_profile_id_on_mood_and_journal.sql — Mood & Journal
20260511_phase2_adult_self_backfill.sql            — Bestehende Nutzer -> adult_self Profil
20260511_completion_questionnaires_subject_profile.sql — Abschluss-Fragebögen
```

### Lokale Drift-Datenbank

Schema-Version 7. Alle oben genannten Spalten sind in den lokalen Drift-Tabellen gespiegelt. Migration-Steps `from < 5`, `< 6`, `< 7` decken bestehende Installationen ab.

---

## Flutter-Änderungen

### Neue Provider

| Provider | Datei | Zweck |
|---|---|---|
| `subjectProfilesProvider` | `reflex_profile_provider.dart` | Alle Profile des Accounts |
| `selectedSubjectProfileProvider` | `reflex_profile_provider.dart` | Aktiv ausgewähltes Profil |
| `latestReflexProfileForSubjectProvider` (family) | `reflex_profile_provider.dart` | Letztes Assessment eines konkreten Profils |
| `latestReflexProfileForSelectedSubjectProvider` | `reflex_profile_provider.dart` | Abkürzung: aktives Profil |
| `trainerClientSharedProfilesProvider` (family) | `trainer_provider.dart` | Vom Klienten freigegebene Profile pro Trainer |

### Geänderte Screens

**Dashboard / Profil-Switcher**  
Oben im Dashboard sichtbar welches Profil aktiv ist; Wechsel per Tippen.

**`progress_overview_screen.dart`**  
`_ReflexProfileCard` filtert nach aktivem Profil: bei Kind-Profil wird nur das Assessment dieses Kindes gezeigt, bei `adult_self` die Gesamtliste.

**`reflex_profile_result_screen.dart`**  
Nutzt `latestReflexProfileForSelectedSubjectProvider` statt globalem Provider.

**`trainer_client_detail_screen.dart`**  
- Sektion „Freigegebene Reflexprofile" mit `_SharedProfileHeader` (Name + Alter)  
- Pro Profil: Assessment-Karte + Notizen  
- Sicherheitshinweise via `trainerFlagLabel` konkret aufgelistet  
- Termine zeigen `„für Max"` / `„für Max + Emma"` in Primärfarbe

**`appointment_scheduler_screen.dart`**  
`_ProfileSelector` (FilterChips) zur Profilzuordnung beim Erstellen eines Termins; nach RPC-Aufruf werden die gewählten Profile in `appointment_subject_profiles` eingetragen.

**`accompaniment_screen.dart`**  
`_AppointmentRow` zeigt `„für $profileLabel"` unter dem Datum.

**`admin_panel_screen.dart`**  
- `_ReflexAnalyticsSummary` hat neues Feld `safetyFlags`  
- Sektion „Sicherheitsrelevante Angaben" (q061, q109–q112) mit Ja-Zählungen  
- Sicherheitsfragen sind aus `topQuestions` herausgenommen (kein Doppelzählen)  
- CSV-Export enthält Bereich `sicherheit`  
- Admin-RPC nutzt `age_group_at_assessment` für korrekte historische Altersgruppierung

**`progress_provider.dart`**  
`completeEnrollment` und extend-Fall geben `subjectProfileId` aus dem Enrollment weiter an Drift-Insert und Supabase-Upsert.

### Appointment-Modell

`Appointment` hat neue Felder `subjectProfileIds`, `subjectProfileNames` und den berechneten Getter `profileLabel` (`„Max"`, `„Max + Emma"` oder `null`).

---

## Datenmigration (Phase 2 Backfill)

Der Backfill-Script hat für alle bestehenden Nutzer mit Trainingsdaten ein `adult_self`-Profil angelegt und alle alten Zeilen ohne `subject_profile_id` diesem Profil zugeordnet.

Ergebnis nach Ausführung:
- 23 `adult_self`-Profile angelegt / vorhanden
- `mood_checkins` unlinked: 0
- `journal_entries` unlinked: 0
- `adult_self_report`-Assessments unlinked: 0
- 6 Enrollments unlinked (Legacy: mehrere aktive Pakete pro Nutzer — intentional)
- 9 `child_parent_report`-Assessments unlinked (kein Kind-Profil zuweisbar — erwartet)

Nachträglicher Backfill (2026-05-12):
- `completion_questionnaires` unlinked: 0 (4 Zeilen via `20260512_completion_questionnaires_backfill_via_user.sql` nachträglich verknüpft — über `enrollments.user_id` → `adult_self`-Profil)

---

## RLS-Sicherheitsmodell

- Trainer sehen Profil-Daten **nur** wenn `reflex_profile_trainer_shares.revoked_at IS NULL`
- Widerruf greift sofort auf DB-Ebene, kein Flutter-Code nötig
- `appointment_subject_profiles` hat eigene Trainer-Insert-Policy
- Admin-RPC prüft `role = 'admin'` vor jedem Zugriff

---

## Offene Punkte (Phase 4 — bewusst zurückgestellt)

Diese Punkte sind im Architekturplan als letzte Phase definiert und werden erst angegangen wenn alle aktiven Daten stabil migriert sind:

1. `subject_profile_id` für neue Trainingsdaten **verpflichtend** machen (NOT NULL-Constraint)
2. Legacy-Fallbacks in Providern entfernen (`user_id`-only Queries)
3. Alte Unique-Indizes (`enrollments_legacy_user_package_active_unique`) entfernen
4. Einmalige UI-Zuordnungsfrage: „Zu wem gehört dein bisheriges Training?" für den Edge-Case mit unverknüpften Enrollments
