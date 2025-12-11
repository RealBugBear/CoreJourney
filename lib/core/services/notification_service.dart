import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../features/progress/domain/models/user_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder(DateTime lastTrainingTime) async {
    // Schedule for the next day at the same time
    final now = tz.TZDateTime.now(tz.local);
    
    // Convert lastTrainingTime to TZDateTime
    // We want the time component from lastTrainingTime, but the date should be tomorrow relative to now
    // Actually, simpler: just add 24 hours to the lastTrainingTime, but ensure it's in the future relative to now.
    // If lastTrainingTime was just now, then lastTrainingTime + 24h is definitely in the future.
    
    // However, we want to be robust.
    // Let's say we want to schedule it for "Tomorrow at HH:MM" where HH:MM comes from lastTrainingTime.
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      lastTrainingTime.hour,
      lastTrainingTime.minute,
    );

    // If the constructed time is in the past (e.g. training was at 8am, now it's 9am), add 1 day.
    // But wait, the requirement is "after the last training".
    // If I train at 8am today, I want a reminder at 8am tomorrow.
    // So if I train now, I want a reminder in 24 hours.
    
    // Let's just use the time from lastTrainingTime and schedule it for tomorrow.
    scheduledDate = scheduledDate.add(const Duration(days: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Zeit für dein Training!',
      'Halte deinen Streak und trainiere jetzt.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Tägliche Erinnerung',
          channelDescription: 'Erinnerung an das tägliche Training',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // This makes it repeat daily at this time
    );
  }

  Future<void> scheduleReminderWindow({
    required DateTime date,
    required HabitWindow window,
    int baseId = 100,
    String? message,
  }) async {
    if (!_isWithinQuietHours(window, date)) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        window.start.hour,
        window.start.minute,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId,
        'Zeit für dein Training!',
        message ?? 'Dein bevorzugtes Trainingsfenster hat begonnen.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_window',
            'Trainingsfenster',
            channelDescription: 'Erinnerungen innerhalb des Wunschzeitraums',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final failoverDate = scheduledDate.add(const Duration(minutes: 45));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + 1,
        'Kleiner Stups',
        'Du kannst die Einheit noch heute erledigen. Nimm dir 15 Minuten!',
        failoverDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_window_failover',
            'Trainingsfenster Follow-up',
            channelDescription: 'Zusätzliche Hinweise, wenn die erste Erinnerung nicht geöffnet wurde',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleWeeklyTouchpoints({
    required DateTime weekStart,
    required UserPreferences preferences,
  }) async {
    if (preferences.silentMode) return;

    final kickoff = tz.TZDateTime(
      tz.local,
      weekStart.year,
      weekStart.month,
      weekStart.day,
      7,
      30,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      200,
      'Starte deine Woche',
      'Plane deine fünf Trainingstage und sichere dir deinen 5/7-Streak.',
      kickoff,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_kickoff',
          'Wöchentlicher Start',
          channelDescription: 'Montagmorgens die Woche planen',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (preferences.midweekCheckinEnabled) {
      final midweek = kickoff.add(const Duration(days: 2));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        201,
        'Wo stehst du diese Woche?',
        'Mittwochs-Check-in: Was braucht es, um 5/7 zu schaffen?',
        midweek,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_midweek',
            'Wochenmitte',
            channelDescription: 'Motivations-Check-in am Mittwoch',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    final closeout = kickoff.add(const Duration(days: 6, hours: 11));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      202,
      'Wochenausklang',
      'Schließe die Woche ab und bereite die nächste vor.',
      closeout,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_closeout',
          'Wochenausklang',
          channelDescription: 'Sonntags-Zusammenfassung und Ausblick',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleMakeUpPlan(DateTime date) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      20,
      0,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      300,
      'Noch ist Zeit für heute',
      'Eine kurze 15-Minuten-Einheit bewahrt deinen 5/7-Puffer.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_makeup',
          'Aufhol-Erinnerung',
          channelDescription: 'Ermutigung für eine Recovery-Session',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminderWindow(int baseId) async {
    await flutterLocalNotificationsPlugin.cancel(baseId);
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }

  bool _isWithinQuietHours(HabitWindow window, DateTime date) {
    final start = DateTime(date.year, date.month, date.day, window.start.hour, window.start.minute);
    final end = DateTime(date.year, date.month, date.day, window.end.hour, window.end.minute);

    final quietStart = DateTime(date.year, date.month, date.day, 22);
    final quietEnd = DateTime(date.year, date.month, date.day, 6);

    return start.isBefore(quietEnd) || end.isAfter(quietStart);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
