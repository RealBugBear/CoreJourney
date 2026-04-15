import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';

// device_calendar temporarily disabled — crashes on iOS 26.2.1 (EKEventStore init).
// CalendarService returns stubs until the plugin is re-enabled or replaced.

/// Stub replacing device_calendar's Calendar type.
class AppCalendar {
  final String id;
  final String name;
  const AppCalendar({required this.id, required this.name});
}

class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot({required this.start, required this.end});

  String get formattedRange {
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s – $e';
  }
}

class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  Future<bool> requestPermissions() async => false;

  Future<bool> hasPermissions() async => false;

  Future<List<AppCalendar>> getAvailableCalendars() async => [];

  Future<String?> getSelectedCalendarId() async => null;

  Future<void> setSelectedCalendarId(String calendarId) async {}

  Future<List<TimeSlot>> findFreeSlots({
    required DateTime from,
    required DateTime until,
    Duration slotDuration = const Duration(hours: 1),
    TimeOfDay earliestTime = const TimeOfDay(hour: 9, minute: 0),
    TimeOfDay latestTime = const TimeOfDay(hour: 19, minute: 0),
  }) async {
    appLogger.w('CalendarService: device_calendar disabled on iOS 26');
    return [];
  }

  Future<String?> createCalendarEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required Duration duration,
    String? location,
    String? description,
  }) async =>
      null;

  Future<void> updateCalendarEvent({
    required String calendarId,
    required String eventId,
    DateTime? newStart,
    Duration? newDuration,
    String? location,
    String? description,
  }) async {}

  Future<void> deleteCalendarEvent({
    required String calendarId,
    required String eventId,
  }) async {}
}
