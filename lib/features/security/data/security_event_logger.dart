import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/security_event.dart';

class SecurityEventLogger {
  final FlutterSecureStorage _storage;
  static const String _storageKey = 'pb_security_events_log';
  static const int maxEventsCount = 100;

  SecurityEventLogger({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> log(
    SecurityEventType eventType, {
    int? userId,
    String? action,
  }) async {
    final event = SecurityEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      userId: userId,
      platform: defaultTargetPlatform.name,
      action: action,
    );

    if (kDebugMode) {
      debugPrint(
        '[SecurityEvent] ${event.eventType.code} | User: ${event.userId ?? "N/A"} | Platform: ${event.platform}${event.action != null ? " | Action: ${event.action}" : ""}',
      );
    }

    try {
      final existingEvents = await getEvents();
      final updatedList = [event, ...existingEvents];
      if (updatedList.length > maxEventsCount) {
        updatedList.removeRange(maxEventsCount, updatedList.length);
      }

      final jsonList = updatedList.map((e) => e.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(jsonList));
    } catch (_) {
      // Storage logging failure should never crash the app
    }
  }

  Future<List<SecurityEvent>> getEvents({int? limit}) async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final events = decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => SecurityEvent.fromJson(e))
            .toList();
        if (limit != null && limit > 0 && events.length > limit) {
          return events.sublist(0, limit);
        }
        return events;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> clearEvents() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }
}
