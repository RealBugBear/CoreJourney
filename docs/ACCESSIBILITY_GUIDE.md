# Accessibility Guide - Grayscale-Kompatibles Design

Dieses Dokument beschreibt, wie das Theme-System von CoreJourney für optimale Accessibility gestaltet ist, insbesondere für die Verwendung mit Graustufen-Filtern auf Smartphones.

## Übersicht

Das App-Design folgt dem Prinzip "Kontrast vor Farbe". Alle wichtigen visuellen Unterscheidungen basieren auf Helligkeitskontrasten und nicht ausschließlich auf Farbunterschieden. Dadurch bleibt die App auch im Graustufen-Modus (z.B. bei aktiviertem Accessibility-Filter auf iOS oder Android) vollständig nutzbar.

## Design-Prinzipien

### 1. Luminanz-basierte Farbpalette

Alle Farben in `AppColors` sind nach ihrer **Luminanz** (Helligkeit) ausgewählt:

```dart
// Beispiel: Semantische Farben mit unterschiedlichen Luminanzwerten
static const Color success = Color(0xFF34C759);  // Luminanz: ~55%
static const Color warning = Color(0xFFFF9500);  // Luminanz: ~65%
static const Color error = Color(0xFFFF3B30);    // Luminanz: ~40%
static const Color info = Color(0xFF007AFF);     // Luminanz: ~50%
```

Im Graustufen-Modus werden diese Farben zu unterscheidbar hellen Grautönen:
- **Error** → Dunkles Grau
- **Info/Primary** → Mittleres Grau
- **Success** → Hell-mittleres Grau
- **Warning** → Helles Grau

### 2. WCAG AAA Konformität

Alle Text-Hintergrund-Kombinationen erfüllen den **WCAG AAA Standard** mit mindestens 7:1 Kontrast-Verhältnis.

```dart
// Beispiel: Kontrast-sichere Text-Farben
AppColors.textPrimary      // Luminanz ~10% auf
AppColors.white            // Luminanz ~100%
// = Kontrast: 18.5:1 ✅
```

### 3. Zusätzliche visuelle Hinweise

Farbe ist niemals der einzige Indikator für Status oder Bedeutung:

- **Buttons**: Elevation + Schatten + Border (nicht nur Farbe)
- **Inputs**: Border-Width-Änderung bei Focus (1px → 2px)
- **Cards**: Border + Elevation
- **Status**: Icons zusätzlich zur Farbe

## Verwendung im Code

### Semantische Farben nutzen

Verwenden Sie **immer** die semantischen Farben aus `AppSemanticColors`:

```dart
// ✅ RICHTIG
Container(
  color: context.semanticColors.success,
  child: Text(
    'Erfolg!',
    style: TextStyle(color: context.semanticColors.onSuccess),
  ),
)

// ❌ FALSCH - Hardcoded Farben
Container(
  color: Colors.green,  // Nicht grayscale-optimiert!
  child: Text('Erfolg!'),
)
```

### Status-Indikatoren mit Icons

Kombinieren Sie Farbe immer mit Icons:

```dart
// ✅ RICHTIG
Row(
  children: [
    Icon(Icons.check_circle, color: context.semanticColors.success),
    Text('Training abgeschlossen'),
  ],
)

// ❌ FALSCH - Nur Farbe
Container(
  color: Colors.green,
  child: Text('Training abgeschlossen'),
)
```

### Kontrast-sichere Textfarben

Verwenden Sie die Helper-Funktion für automatische Textfarben:

```dart
final backgroundColor = AppColors.primary;
final textColor = AppColors.getContrastText(backgroundColor);

Text(
  'Hello',
  style: TextStyle(color: textColor),
)
```

## Testing für Grayscale-Kompatibilität

### iOS Testing

1. **Graustufen-Filter aktivieren**:
   - Einstellungen → Bedienungshilfen → Anzeige & Textgröße
   - "Farbfilter" aktivieren
   - "Graustufen" auswählen

2. **App testen**:
   ```bash
   flutter run -t lib/main_development.dart
   ```

3. **Kritische Checkpoints**:
   - [ ] Buttons sind vom Hintergrund unterscheidbar
   - [ ] Navigation-Elemente sind klar erkennbar
   - [ ] Text hat ausreichenden Kontrast
   - [ ] Success/Warning/Error-States sind unterscheidbar
   - [ ] Input-Focus ist visuell erkennbar
   - [ ] Cards haben sichtbare Grenzen

### Android Testing

1. **Graustufen-Modus aktivieren**:
   - Einstellungen → Bedienungshilfen → Farbkorrektur
   - "Farbkorrektur verwenden" aktivieren
   - "Graustufen" auswählen

2. Gleiche Test-Checkpoints wie bei iOS

### Dark Mode Testing

Dark Mode funktioniert oft **besser** im Grayscale-Modus, da die Kontraste klarer sind:

```bash
# 1. System auf Dark Mode stellen
# 2. App starten
flutter run -t lib/main_development.dart
# 3. Graustufen-Filter aktivieren
# 4. Validieren
```

## Best Practices für neue Features

### ✅ DO's

1. **Verwende AppColors konstant**:
   ```dart
   color: AppColors.primary
   ```

2. **Nutze semantische Farben**:
   ```dart
   color: context.semanticColors.success
   ```

3. **Kombiniere Farbe mit anderen Hinweisen**:
   ```dart
   // Icon + Text + Farbe
   Row(
     children: [
       Icon(Icons.error, color: context.semanticColors.error),
       Text('Fehler aufgetreten'),
     ],
   )
   ```

4. **Verwende Borders für Separation**:
   ```dart
   Container(
     decoration: BoxDecoration(
       border: Border.all(color: AppColors.divider),
     ),
   )
   ```

### ❌ DON'Ts

1. **Keine hardcoded Farben**:
   ```dart
   color: Color(0xFF123456)  // ❌
   color: Colors.red         // ❌
   ```

2. **Farbe nicht als einziger Indikator**:
   ```dart
   // ❌ Nur Farbe für Status
   Container(color: status == 'active' ? Colors.green : Colors.red)
   
   // ✅ Farbe + Icon
   Row(children: [
     Icon(status == 'active' ? Icons.check : Icons.error),
     Container(color: status == 'active' 
       ? context.semanticColors.success 
       : context.semanticColors.error),
   ])
   ```

3. **Keine Text-Farben ohne Kontrast-Prüfung**:
   ```dart
   // ❌ Kann zu wenig Kontrast haben
   Text('Hello', style: TextStyle(color: Colors.grey))
   
   // ✅ Verwende vordefinierte Text-Farben
   Text('Hello', style: Theme.of(context).textTheme.bodyMedium)
   ```

## Farbpalette Referenz

| Farbe | Hex | Luminanz | Grayscale |
|-------|-----|----------|-----------|
| **Primary** | `#6B4CE6` | ~45% | Mittleres Grau |
| **Success** | `#34C759` | ~55% | Hell-mittel |
| **Warning** | `#FF9500` | ~65% | Helles Grau |
| **Error** | `#FF3B30` | ~40% | Dunkles Grau |
| **Info** | `#007AFF` | ~50% | Mittleres Grau |

## Kontrast-Anforderungen

| Element | Mindest-Kontrast | Standard |
|---------|------------------|----------|
| Normal Text | 7:1 | WCAG AAA |
| Großer Text | 4.5:1 | WCAG AAA |
| UI-Komponenten | 3:1 | WCAG AA |
| Fokus-Indikatoren | 3:1 | WCAG AA |

## Tools & Resources

- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Flutter Accessibility**: https://docs.flutter.dev/development/accessibility-and-localization/accessibility
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/

## Support

Bei Fragen zum Accessibility-Design oder zur Implementierung wenden Sie sich an das Development-Team.
