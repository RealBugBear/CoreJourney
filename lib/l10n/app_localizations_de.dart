// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'CoreJourney';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get passwordResetSent =>
      'Wir haben dir eine E-Mail zum Zurücksetzen des Passworts gesendet.';

  @override
  String get authErrorInvalidCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authErrorEmailInUse =>
      'Diese E-Mail-Adresse ist bereits registriert.';

  @override
  String get authErrorWeakPassword =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get startTraining => 'Training starten';

  @override
  String currentDay(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String get dailyStreak => 'Tages-Streak';

  @override
  String weeklyProgress(int count, int goal) {
    return '$count von $goal diese Woche';
  }

  @override
  String get goldenDay => 'Golden Day';

  @override
  String daysRemaining(int days) {
    return '$days Tage verbleibend';
  }

  @override
  String get trainingMode => 'Trainingsmodus';

  @override
  String get tutorialMode => 'Tutorial';

  @override
  String get routineMode => 'Routine';

  @override
  String get silentMode => 'Silent';

  @override
  String get hapticMode => 'Haptisch';

  @override
  String get voiceCuesMode => 'Stimme & Cues';

  @override
  String get exercisePosition => 'Ausgangsposition';

  @override
  String get exerciseMovement => 'Bewegung';

  @override
  String get exerciseHints => 'Hinweise';

  @override
  String exerciseReps(int count) {
    return '$count Wiederholungen';
  }

  @override
  String get sessionComplete => 'Training abgeschlossen';

  @override
  String get sessionCompleteSubtitle =>
      'Gut gemacht! Du hast dein Training für heute abgeschlossen.';

  @override
  String get moodCheckIn => 'Wie geht es dir?';

  @override
  String get moodLabel => 'Stimmung';

  @override
  String get energyLabel => 'Energie';

  @override
  String get stressLabel => 'Stress';

  @override
  String get moodSkip => 'Überspringen';

  @override
  String get moodSubmit => 'Speichern';

  @override
  String get moodChartEmpty =>
      'Schließe eine Trainingseinheit ab, um deine Stimmung zu verfolgen.';

  @override
  String get intakeAssessmentTitle => 'Erstes Assessment';

  @override
  String get questionIsometricWithTrainer =>
      'Hast du eine isometrische Aktivierung mit einem Trainer erhalten?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String durationRecommendation(int weeks) {
    return 'Empfohlene Dauer: $weeks Wochen';
  }

  @override
  String get adjustDuration => 'Dauer anpassen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get completionQuestionnaireTitle => 'Block abgeschlossen?';

  @override
  String get completionQuestion =>
      'Hattest du durch das Training eine verstärkte emotionale oder stressige Zeit und konntest dich mit diesen Themen konfrontieren – zu erkennen, dass deine emotionale Reaktion nicht immer mit der Realität übereinstimmt – und anfangen dich zu regulieren?';

  @override
  String get completionYes => 'Ja, ich bin bereit';

  @override
  String get completionNotYet => 'Noch nicht';

  @override
  String get packages => 'Programm';

  @override
  String get packageLocked => 'Gesperrt';

  @override
  String get packageCurrent => 'Aktuell';

  @override
  String get packageCompleted => 'Abgeschlossen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsTraining => 'Training';

  @override
  String get settingsReminders => 'Erinnerungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsTheme => 'Erscheinungsbild';

  @override
  String get settingsWeeklyGoal => 'Wochenziel';

  @override
  String get settingsChildAssist => 'Kinderunterstützung';

  @override
  String get settingsConnectTrainer => 'Trainer verbinden';

  @override
  String get reminderEnabled => 'Erinnerungen aktiviert';

  @override
  String get reminderWindow => 'Erinnerungsfenster';

  @override
  String get quietHours => 'Ruhezeiten';

  @override
  String get disclaimer => 'Medizinischer Hinweis';

  @override
  String get disclaimerText =>
      'Dieses Training ersetzt keine medizinische Behandlung. Bitte konsultiere einen Arzt, wenn du gesundheitliche Bedenken hast. Achte auf die Signale deines Körpers und mache Pausen, wenn nötig.';

  @override
  String get disclaimerAccept => 'Verstanden, weiter';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorNoNetwork => 'Keine Internetverbindung.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get trainerClients => 'Meine Klienten';

  @override
  String get trainerNoClients =>
      'Noch keine Klienten verknüpft. Generiere einen Einladungscode und teile ihn.';

  @override
  String get trainerInviteCode => 'Einladungscode';

  @override
  String get trainerGenerateCode => 'Code generieren';

  @override
  String get trainerNotes => 'Notizen';

  @override
  String get connectToTrainer => 'Mit Trainer verbinden';

  @override
  String get enterInviteCode => 'Einladungscode eingeben';
}
