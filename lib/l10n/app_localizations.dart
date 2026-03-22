import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// App title
  ///
  /// In de, this message translates to:
  /// **'CoreJourney'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get resetPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir eine E-Mail zum Zurücksetzen des Passworts gesendet.'**
  String get passwordResetSent;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In de, this message translates to:
  /// **'E-Mail oder Passwort ist falsch.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In de, this message translates to:
  /// **'Diese E-Mail-Adresse ist bereits registriert.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort muss mindestens 8 Zeichen lang sein.'**
  String get authErrorWeakPassword;

  /// No description provided for @dashboard.
  ///
  /// In de, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @startTraining.
  ///
  /// In de, this message translates to:
  /// **'Training starten'**
  String get startTraining;

  /// No description provided for @currentDay.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} von {total}'**
  String currentDay(int day, int total);

  /// No description provided for @dailyStreak.
  ///
  /// In de, this message translates to:
  /// **'Tages-Streak'**
  String get dailyStreak;

  /// No description provided for @weeklyProgress.
  ///
  /// In de, this message translates to:
  /// **'{count} von {goal} diese Woche'**
  String weeklyProgress(int count, int goal);

  /// No description provided for @goldenDay.
  ///
  /// In de, this message translates to:
  /// **'Golden Day'**
  String get goldenDay;

  /// No description provided for @daysRemaining.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage verbleibend'**
  String daysRemaining(int days);

  /// No description provided for @trainingMode.
  ///
  /// In de, this message translates to:
  /// **'Trainingsmodus'**
  String get trainingMode;

  /// No description provided for @tutorialMode.
  ///
  /// In de, this message translates to:
  /// **'Tutorial'**
  String get tutorialMode;

  /// No description provided for @routineMode.
  ///
  /// In de, this message translates to:
  /// **'Routine'**
  String get routineMode;

  /// No description provided for @silentMode.
  ///
  /// In de, this message translates to:
  /// **'Silent'**
  String get silentMode;

  /// No description provided for @hapticMode.
  ///
  /// In de, this message translates to:
  /// **'Haptisch'**
  String get hapticMode;

  /// No description provided for @voiceCuesMode.
  ///
  /// In de, this message translates to:
  /// **'Stimme & Cues'**
  String get voiceCuesMode;

  /// No description provided for @exercisePosition.
  ///
  /// In de, this message translates to:
  /// **'Ausgangsposition'**
  String get exercisePosition;

  /// No description provided for @exerciseMovement.
  ///
  /// In de, this message translates to:
  /// **'Bewegung'**
  String get exerciseMovement;

  /// No description provided for @exerciseHints.
  ///
  /// In de, this message translates to:
  /// **'Hinweise'**
  String get exerciseHints;

  /// No description provided for @exerciseReps.
  ///
  /// In de, this message translates to:
  /// **'{count} Wiederholungen'**
  String exerciseReps(int count);

  /// No description provided for @sessionComplete.
  ///
  /// In de, this message translates to:
  /// **'Training abgeschlossen'**
  String get sessionComplete;

  /// No description provided for @sessionCompleteSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gut gemacht! Du hast dein Training für heute abgeschlossen.'**
  String get sessionCompleteSubtitle;

  /// No description provided for @moodCheckIn.
  ///
  /// In de, this message translates to:
  /// **'Wie geht es dir?'**
  String get moodCheckIn;

  /// No description provided for @moodLabel.
  ///
  /// In de, this message translates to:
  /// **'Stimmung'**
  String get moodLabel;

  /// No description provided for @energyLabel.
  ///
  /// In de, this message translates to:
  /// **'Energie'**
  String get energyLabel;

  /// No description provided for @stressLabel.
  ///
  /// In de, this message translates to:
  /// **'Stress'**
  String get stressLabel;

  /// No description provided for @moodSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get moodSkip;

  /// No description provided for @moodSubmit.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get moodSubmit;

  /// No description provided for @moodChartEmpty.
  ///
  /// In de, this message translates to:
  /// **'Schließe eine Trainingseinheit ab, um deine Stimmung zu verfolgen.'**
  String get moodChartEmpty;

  /// No description provided for @intakeAssessmentTitle.
  ///
  /// In de, this message translates to:
  /// **'Erstes Assessment'**
  String get intakeAssessmentTitle;

  /// No description provided for @questionIsometricWithTrainer.
  ///
  /// In de, this message translates to:
  /// **'Hast du eine isometrische Aktivierung mit einem Trainer erhalten?'**
  String get questionIsometricWithTrainer;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @durationRecommendation.
  ///
  /// In de, this message translates to:
  /// **'Empfohlene Dauer: {weeks} Wochen'**
  String durationRecommendation(int weeks);

  /// No description provided for @adjustDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer anpassen'**
  String get adjustDuration;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @completionQuestionnaireTitle.
  ///
  /// In de, this message translates to:
  /// **'Block abgeschlossen?'**
  String get completionQuestionnaireTitle;

  /// No description provided for @completionQuestion.
  ///
  /// In de, this message translates to:
  /// **'Hattest du durch das Training eine verstärkte emotionale oder stressige Zeit und konntest dich mit diesen Themen konfrontieren – zu erkennen, dass deine emotionale Reaktion nicht immer mit der Realität übereinstimmt – und anfangen dich zu regulieren?'**
  String get completionQuestion;

  /// No description provided for @completionYes.
  ///
  /// In de, this message translates to:
  /// **'Ja, ich bin bereit'**
  String get completionYes;

  /// No description provided for @completionNotYet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht'**
  String get completionNotYet;

  /// No description provided for @packages.
  ///
  /// In de, this message translates to:
  /// **'Programm'**
  String get packages;

  /// No description provided for @packageLocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get packageLocked;

  /// No description provided for @packageCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get packageCurrent;

  /// No description provided for @packageCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get packageCompleted;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @settingsTraining.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get settingsTraining;

  /// No description provided for @settingsReminders.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get settingsReminders;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get settingsTheme;

  /// No description provided for @settingsWeeklyGoal.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel'**
  String get settingsWeeklyGoal;

  /// No description provided for @settingsChildAssist.
  ///
  /// In de, this message translates to:
  /// **'Kinderunterstützung'**
  String get settingsChildAssist;

  /// No description provided for @settingsConnectTrainer.
  ///
  /// In de, this message translates to:
  /// **'Trainer verbinden'**
  String get settingsConnectTrainer;

  /// No description provided for @reminderEnabled.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen aktiviert'**
  String get reminderEnabled;

  /// No description provided for @reminderWindow.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungsfenster'**
  String get reminderWindow;

  /// No description provided for @quietHours.
  ///
  /// In de, this message translates to:
  /// **'Ruhezeiten'**
  String get quietHours;

  /// No description provided for @disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Medizinischer Hinweis'**
  String get disclaimer;

  /// No description provided for @disclaimerText.
  ///
  /// In de, this message translates to:
  /// **'Dieses Training ersetzt keine medizinische Behandlung. Bitte konsultiere einen Arzt, wenn du gesundheitliche Bedenken hast. Achte auf die Signale deines Körpers und mache Pausen, wenn nötig.'**
  String get disclaimerText;

  /// No description provided for @disclaimerAccept.
  ///
  /// In de, this message translates to:
  /// **'Verstanden, weiter'**
  String get disclaimerAccept;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte versuche es erneut.'**
  String get errorGeneric;

  /// No description provided for @errorNoNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung.'**
  String get errorNoNetwork;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @trainerClients.
  ///
  /// In de, this message translates to:
  /// **'Meine Klienten'**
  String get trainerClients;

  /// No description provided for @trainerNoClients.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Klienten verknüpft. Generiere einen Einladungscode und teile ihn.'**
  String get trainerNoClients;

  /// No description provided for @trainerInviteCode.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode'**
  String get trainerInviteCode;

  /// No description provided for @trainerGenerateCode.
  ///
  /// In de, this message translates to:
  /// **'Code generieren'**
  String get trainerGenerateCode;

  /// No description provided for @trainerNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get trainerNotes;

  /// No description provided for @connectToTrainer.
  ///
  /// In de, this message translates to:
  /// **'Mit Trainer verbinden'**
  String get connectToTrainer;

  /// No description provided for @enterInviteCode.
  ///
  /// In de, this message translates to:
  /// **'Einladungscode eingeben'**
  String get enterInviteCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
