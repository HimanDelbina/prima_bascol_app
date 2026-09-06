import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/security/data/security_event_logger.dart';
import 'package:prima_bascol_app/features/security/domain/security_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> mockStorage = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key = methodCall.arguments is Map
            ? methodCall.arguments['key']?.toString()
            : null;
        if (methodCall.method == 'read') {
          return key != null ? mockStorage[key] : null;
        } else if (methodCall.method == 'write') {
          final val = methodCall.arguments['value']?.toString() ?? '';
          if (key != null) mockStorage[key] = val;
          return null;
        } else if (methodCall.method == 'delete') {
          if (key != null) mockStorage.remove(key);
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('SecurityEventLogger Tests', () {
    test('logs event with safe metadata only and no credentials', () async {
      final logger = SecurityEventLogger();

      await logger.log(
        SecurityEventType.appLocked,
        userId: 10,
        action: 'auto_lock',
      );

      final events = await logger.getEvents();
      expect(events.length, equals(1));

      final ev = events.first;
      expect(ev.eventType, equals(SecurityEventType.appLocked));
      expect(ev.userId, equals(10));
      expect(ev.action, equals('auto_lock'));
      expect(ev.timestamp, isNotNull);

      // Verify JSON representation does NOT have sensitive keys
      final json = ev.toJson();
      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('pattern'), isFalse);
      expect(json.containsKey('hash'), isFalse);
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('jwt'), isFalse);
    });

    test('maintains chronological order (newest first) and respects limit', () async {
      final logger = SecurityEventLogger();

      for (int i = 1; i <= 5; i++) {
        await logger.log(
          SecurityEventType.sensitiveActionAuthorized,
          userId: 1,
          action: 'action_$i',
        );
      }

      final events = await logger.getEvents(limit: 3);
      expect(events.length, equals(3));
      expect(events[0].action, equals('action_5'));
      expect(events[1].action, equals('action_4'));
      expect(events[2].action, equals('action_3'));
    });

    test('clearEvents removes all stored records', () async {
      final logger = SecurityEventLogger();

      await logger.log(SecurityEventType.logout, userId: 1);
      expect((await logger.getEvents()).length, equals(1));

      await logger.clearEvents();
      expect((await logger.getEvents()).isEmpty, isTrue);
    });
  });
}
