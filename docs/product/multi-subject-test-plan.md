# Mehrpersonen-Training: Testplan

Stand: 2026-05-11

Dieser Plan beschreibt was manuell getestet werden soll, bevor das Feature als stabil gilt. Tests sind nach Bereich geordnet und nach Priorität innerhalb jedes Bereichs.

---

## Vorbereitung

- Dev-App starten: `make run`
- Zwei Testaccounts bereit haben:
  - **Account A** — normaler Nutzer (wird Klient)
  - **Account B** — Trainer-Account
- Account A und B sind bereits verbunden (aktive Trainer-Klient-Beziehung)

---

## 1. Onboarding / Profil-Anlage

### 1a. Neuer Account: Für mich

1. Neuen Account registrieren
2. Kontaktnamen eingeben
3. „Für mich" wählen
4. Verifizieren: `adult_self`-Profil wurde angelegt
5. Verifizieren: Dashboard zeigt „Ich" oder den gewählten Namen oben

### 1b. Neuer Account: Für mein Kind

1. Neuen Account registrieren
2. „Für mein Kind" wählen → Name + Geburtsdatum eingeben
3. Verifizieren: Kind-Profil wurde angelegt
4. Verifizieren: Dashboard zeigt den Kindnamen oben
5. Verifizieren: Kein `adult_self`-Profil erzwungen

### 1c. Bestehender Account ohne Profil

1. Account der den Phase-2-Backfill durchlaufen hat öffnen
2. Verifizieren: Dashboard zeigt ein Profil (nicht leer / kein Fehler)
3. Verifizieren: Trainingsfortschritt ist dem Profil zugeordnet

---

## 2. Profil-Switcher

### 2a. Zwischen Profilen wechseln

1. Account mit mind. 2 Profilen (z.B. „Ich" + Kind „Max")
2. Profil-Switcher im Dashboard antippen
3. Zu „Max" wechseln
4. Verifizieren: Dashboard zeigt Trainingsstand von Max
5. Verifizieren: Reflexprofil-Karte zeigt Maxʼ Assessment (nicht das eigene)
6. Zurück zu „Ich" wechseln
7. Verifizieren: Dashboard zeigt eigenen Trainingsstand

### 2b. Profil hinzufügen

1. Im Profil-Tab oder Switcher: neues Kind-Profil anlegen
2. Verifizieren: erscheint sofort im Switcher

---

## 3. Training pro Profil

### 3a. Getrennte Enrollments

1. Account mit zwei Profilen
2. Für Profil A Moro starten
3. Zu Profil B wechseln
4. Verifizieren: Profil B zeigt kein laufendes Training
5. Moro auch für Profil B starten
6. Verifizieren: beide Profile haben unabhängige Trainingsstände

### 3b. Trainingsfortschritt bleibt profilgebunden

1. Mit Profil A eine Trainingseinheit abschließen
2. Zu Profil B wechseln
3. Verifizieren: Fortschritt von A ist in B nicht sichtbar

### 3c. Abschluss-Fragebogen

1. Enrollment auf Abschluss-Tag bringen (oder direkt in DB setzen)
2. Fragebogen ausfüllen (bestanden oder verlängern)
3. In Supabase prüfen: `completion_questionnaires.subject_profile_id` ist gesetzt

---

## 4. Reflexprofil

### 4a. Reflexprofil pro Kind

1. Profil „Max" auswählen
2. Reflexprofil-Fragebogen starten und abschließen
3. Verifizieren: Ergebnis zeigt Maxʼ Namen
4. Zu eigenem Profil wechseln
5. Verifizieren: Reflexprofil-Karte zeigt das eigene Assessment, nicht Maxʼ

### 4b. Altersgruppe im Assessment korrekt

1. Kind-Profil mit bekanntem Geburtsdatum
2. Fragebogen abschließen
3. In Supabase prüfen: `age_group_at_assessment` enthält korrekte Gruppe (z.B. `5-7`)
4. Geburtsdatum des Kindes ändern (simuliert älter werden)
5. Verifizieren: altes Assessment zeigt noch die alte Altersgruppe

### 4c. Sicherheitsfragen-Popup

1. Im Fragebogen q061 (ADHS/ADS), q109 (Epilepsie) oder q110–q112 mit „Ja" beantworten
2. Verifizieren: Popup erscheint mit Rücksprache-Hinweis
3. Bestätigen und fortfahren
4. Verifizieren: `warning_confirmations` im Assessment enthält den Eintrag

---

## 5. Trainer-Freigabe

### 5a. Profil freigeben

1. Als Klient (Account A): nach Reflexprofil-Abschluss Freigabe für Trainer anbieten
2. Freigabe bestätigen
3. Als Trainer (Account B): Klienten-Detailseite öffnen
4. Verifizieren: freigegebenes Profil mit Assessment sichtbar
5. Verifizieren: Sicherheitshinweise konkret aufgelistet (z.B. „ADHS / ADS angegeben")

### 5b. Freigabe widerrufen

1. Als Klient: Freigabe für Trainer widerrufen
2. Als Trainer: Klienten-Detailseite sofort neu laden
3. Verifizieren: Reflexprofil-Daten dieses Profils sind nicht mehr sichtbar
4. Verifizieren: Profil-Header ggf. noch sichtbar aber ohne Assessment-Inhalt

### 5c. Mehrere Profile — nur freigegebene sichtbar

1. Klient hat zwei Profile: „Max" freigegeben, „Emma" nicht
2. Als Trainer Detailseite öffnen
3. Verifizieren: nur Max erscheint in „Freigegebene Reflexprofile"

---

## 6. Termine mit Profilzuordnung

### 6a. Termin mit einem Profil erstellen (als Trainer)

1. Terminvorschlag erstellen
2. `_ProfileSelector` zeigt freigegebene Profile als FilterChips
3. Ein Profil auswählen (z.B. Max)
4. Termin vorschlagen
5. Verifizieren: Termin in Klienten-Ansicht zeigt „für Max"
6. Verifizieren: Termin im Begleitung-Tab des Klienten zeigt „für Max"

### 6b. Termin für mehrere Profile

1. Terminvorschlag erstellen, zwei Profile wählen (Max + Emma)
2. Verifizieren: Termin zeigt „für Max + Emma" in Primärfarbe

### 6c. Termin ohne Profilzuordnung

1. Terminvorschlag ohne Profile erstellen (allgemeines Elterngespräch)
2. Verifizieren: kein Profil-Label in der Anzeige

---

## 7. Stimmung und Journal

### 7a. Stimmung wird Profil zugeordnet

1. Profil „Max" aktiv
2. Stimmungs-Check-in ausfüllen
3. In Supabase prüfen: `mood_checkins.subject_profile_id` zeigt auf Max-Profil
4. Zu eigenem Profil wechseln, erneut Check-in
5. Verifizieren: die beiden Einträge haben unterschiedliche `subject_profile_id`

### 7b. Journal-Eintrag wird Profil zugeordnet

1. Trainingsnotiz / Journal-Eintrag schreiben (mit Profil Max aktiv)
2. In Supabase prüfen: `journal_entries.subject_profile_id` gesetzt

---

## 8. Admin-Statistik

Voraussetzung: Admin-Account verwenden.

### 8a. Altersgruppen-Verteilung korrekt

1. Admin-Panel → Reflexprofil-Tab öffnen
2. Verifizieren: Altersgruppen-Chips zeigen korrekte Zahlen
3. Ein Kind-Assessment mit bekannter Altersgruppe ist dort vertreten
4. Geburtsdatum des Kindes ändern → altes Assessment behält alte Gruppe (nicht rückwirkend neu gruppiert)

### 8b. Sicherheitsrelevante Angaben

1. Im Admin-Panel Sektion „Sicherheitsrelevante Angaben" sichtbar
2. Verifizieren: Zählungen für ADHS/ADS, Epilepsie, Autismus-Spektrum, Trisomie 21, Psych. Behandlung erscheinen
3. Diese Fragen erscheinen **nicht** zusätzlich in „Häufigste Ja-Antworten"

### 8c. CSV-Export

1. „CSV kopieren" antippen
2. In Texteditor einfügen
3. Verifizieren: Bereich `sicherheit` in den Zeilen vorhanden

---

## 9. Regressionstest — Einzelperson-Account

Für Nutzer ohne Kinder darf sich nichts geändert haben:

1. Account mit nur eigenem `adult_self`-Profil (kein Kind)
2. Dashboard öffnen — kein Switcher-Dropdown nötig (oder nur ein Eintrag)
3. Training starten und fortführen wie bisher
4. Reflexprofil machen — Ergebnis erscheint wie gehabt
5. Stimmungs-Check-in — funktioniert ohne Fehler
6. Begleitung-Tab — Termine ohne Profilzuordnung erscheinen normal

---

## 10. Datenbankzustand nach Tests prüfen

Abschließend im Supabase SQL-Editor kontrollieren:

```sql
-- Keine neuen unverknüpften Zeilen
SELECT 'mood_checkins unlinked',    count(*) FROM mood_checkins    WHERE subject_profile_id IS NULL
UNION ALL
SELECT 'journal_entries unlinked',  count(*) FROM journal_entries  WHERE subject_profile_id IS NULL
UNION ALL
SELECT 'completion_q unlinked',     count(*) FROM completion_questionnaires WHERE subject_profile_id IS NULL;
```

Erwartetes Ergebnis: 0 für alle drei (außer Legacy-Zeilen die vor dem Backfill existierten — diese sollten nach dem Backfill bereits 0 sein).
