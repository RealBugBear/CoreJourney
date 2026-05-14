# Design: Fragebogen Draft-Persistenz (Reflexprofil)

**Datum:** 2026-05-14  
**Status:** Genehmigt  
**Betrifft:** `lib/features/assessment/`

---

## Problem

Der Reflexprofil-Fragebogen umfasst 112 Fragen in 8 Modulen. Bricht ein Nutzer den Fragebogen ab (App schließen, in Hintergrund wechseln, Back-Button), geht der aktuelle Modul-Stand verloren — der Draft wird nur beim Tippen auf „Nächstes Modul" gespeichert. Das führt dazu, dass Nutzer von vorne anfangen müssen, was zu Abbrüchen und App-Aufgabe führt.

**Bestehende Infrastruktur (bleibt unverändert):**
- `saveReflexProfileDraft()` / `loadReflexProfileDraft()` / `deleteReflexProfileDraft()` in `reflex_profile_provider.dart` — speichern Draft als Supabase-Row mit Status `draft`
- Resume-Dialog in `_checkForDraft()` — zeigt „Fortsetzen?" wenn Draft gefunden
- `_saveDraft()` im Screen — serialisiert aktuellen Zustand, ruft Supabase-Funktion auf

**Lücken:**
- Kein `WidgetsBindingObserver` → App-Close triggert keinen Save
- Kein `PopScope` → Back-Button verlässt ohne Save
- Kein lokaler Fallback → Offline-Nutzung ungesichert
- `_checkForDraft()` prüft nur Supabase, nicht lokal

---

## Entscheidungen

| Frage | Entscheidung |
|---|---|
| Offline-Fallback? | Ja — SharedPreferences als lokaler Puffer |
| Save-Granularität? | Per-Antwort lokal + Cloud-Sync beim App-Pause |
| Geräteübergreifend? | Ja — Supabase als Cross-Device Source of Truth |
| Back-Button? | Bestätigungsdialog + sofortiger lokaler Save |

---

## Architektur

### Neuer Service: `DraftPersistenceService`

**Pfad:** `lib/features/assessment/domain/draft_persistence_service.dart`

Eigenständige Klasse, **nur SharedPreferences** — keine Riverpod- oder Flutter-Widget-Abhängigkeit. Bekommt Daten rein, gibt Daten raus.

```dart
class DraftPersistenceService {
  Future<void> saveLocal(String profileId, Map<String, dynamic> draftJson);
  Future<Map<String, dynamic>?> loadLocal(String profileId);
  Future<void> clearLocal(String profileId);
}
```

**Storage-Key:** `reflex_draft_<profileId>` in SharedPreferences

Die Cloud-Aufrufe (`syncToCloud`, `loadBest`-Vergleich) verbleiben im Screen, wo `WidgetRef` bereits verfügbar ist. Klare Trennung: Service = lokale Schicht, Screen = Orchestrierung beider Schichten.

### Änderungen am `ReflexProfileScreen`

| Änderung | Zweck |
|---|---|
| `WidgetsBindingObserver` mixin | `didChangeAppLifecycleState(paused)` → `_draftService.saveLocal()` + bestehende `_saveDraft()` (Supabase) |
| Per-Antwort `saveLocal()` | Nach `_setYesNoAnswer()`, Multiselect, Months-Input |
| Text-Debounce 300ms | `onChange` Textfelder → `saveLocal()` nach 300ms Stille |
| `PopScope` um Questionnaire-Widget | Bestätigungsdialog + `saveLocal()` vor Exit |
| `_checkForDraft()` erweitern | Prüft lokal + Supabase, nimmt neueren Timestamp |

---

## Datenfluss

### Save-Pfad (3 Trigger)

```
1. Nutzer gibt Antwort (Ja/Nein/Multiselect/Months)
   → setState() → saveLocal(profileId, snapshot)     ← synchron, <1ms

2. Nutzer tippt in Textfeld
   → Debounce 300ms → saveLocal(profileId, snapshot)

3. App geht in Hintergrund
   → didChangeAppLifecycleState(paused)
   → syncToCloud(profileId)                          ← fire-and-forget, Fehler ignoriert
```

### Resume-Pfad

```
Nutzer tippt auf Profil → _checkForDraft(profileId) (erweitert)
   ├── _draftService.loadLocal()      → SharedPreferences-Draft + __meta.saved_at
   ├── loadReflexProfileDraft()       → Supabase-Draft + updated_at
   └── Timestamp-Vergleich im Screen
       ├── Kein Draft gefunden  → direkt starten (unverändert)
       └── Draft gefunden       → bestehender Resume-Dialog (unverändert)
```

### Abschluss

```
Nutzer schließt Fragebogen erfolgreich ab
→ clearLocal(profileId)               ← SharedPreferences
→ deleteReflexProfileDraft(profileId) ← Supabase (bestehend)
```

---

## Lokales JSON-Format

Minimale Erweiterung des bestehenden Formats — nur `saved_at` im `__meta`-Block neu:

```json
{
  "__meta": {
    "module_index": 2,
    "questionnaire_for": "child",
    "saved_at": "2026-05-14T10:30:00.000Z"
  },
  "q001": { "yesNoUnknown": true },
  "q002": { "text": "Beispieltext" },
  "q003": { "selectedOptionIds": ["opt_a", "opt_b"] }
}
```

Das Format ist identisch mit dem bestehenden Supabase-`answers`-JSONB-Feld — kein separater Serialisierungs-/Deserialisierungspfad nötig.

---

## Fehlerbehandlung

| Szenario | Verhalten |
|---|---|
| `saveLocal()` schlägt fehl | Silent catch — SharedPreferences-Fehler praktisch unmöglich auf modernen Geräten |
| `syncToCloud()` offline | Silent catch — lokal gesichert, nächster Pause-Event wiederholt Sync |
| `loadBest()` Cloud-Fehler | Nur lokalen Draft zurückgeben, kein Nutzer-Feedback |
| `loadBest()` beide leer | `null` → normaler Start |
| Lokaler Draft korrupt | Catch → `null`, korrupten Draft löschen, normaler Start |
| App hard-crash | Max. Verlust = letzte Texteingabe innerhalb 300ms Debounce-Fenster |

**Kein Retry-Mechanismus** — der nächste App-Pause-Event ist der natürliche Retry.

---

## PopScope-Dialog

```
Titel: "Fragebogen verlassen?"
Text:  "Dein Fortschritt wird gespeichert. Du kannst jederzeit weitermachen."
Buttons:
  - "Abbrechen"  → Dialog schließen, Fragebogen fortsetzen
  - "Verlassen"  → saveLocal() + Navigator.pop()
```

---

## Testing

**Unit-Tests:** `test/features/assessment/domain/draft_persistence_service_test.dart`

| Test | Beschreibung |
|---|---|
| Round-trip | `saveLocal` + `loadLocal` serialisiert/deserialisiert korrekt |
| `loadBest` lokal neuer | Lokaler Draft gewinnt |
| `loadBest` Cloud neuer | Supabase-Draft gewinnt |
| `loadBest` nur lokal | Lokaler Draft zurückgegeben |
| `loadBest` nur Cloud | Cloud-Draft zurückgegeben |
| `loadBest` beide leer | `null` zurückgegeben |
| Korruptes JSON | `null` ohne Crash, Draft gelöscht |
| `clearLocal` | Draft danach nicht abrufbar |

**Keine Widget-Tests** für Screen-Änderungen — Lifecycle/PopScope/Debounce werden manuell verifiziert.

---

## Betroffene Dateien

**Neu:**
- `lib/features/assessment/domain/draft_persistence_service.dart`
- `test/features/assessment/domain/draft_persistence_service_test.dart`

**Geändert:**
- `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`
  - `WidgetsBindingObserver` mixin
  - Per-Antwort `saveLocal()` Calls
  - Text-Debounce
  - `PopScope` mit Dialog
  - `_checkForDraft()` → `loadBest()` Umstellung

**Unverändert:**
- `lib/features/assessment/presentation/providers/reflex_profile_provider.dart` (Supabase-Funktionen bleiben as-is)
- Supabase-Schema (kein Migration nötig)
- Resume-Dialog UI
