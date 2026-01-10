import 'package:flutter_test/flutter_test.dart';
import 'package:chrono_calendar/data/models/event_model.dart';

void main() {
  group('EventModel', () {
    group('create', () {
      test('创建新事件生成正确的默认值', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '测试事件',
          dtStart: DateTime(2026, 1, 10, 14, 0),
        );

        expect(event.uid, isNotEmpty);
        expect(event.calendarId, 'calendar-1');
        expect(event.summary, '测试事件');
        expect(event.isAllDay, isFalse);
        expect(event.status, EventStatus.confirmed);
        expect(event.priority, 0);
        expect(event.sequence, 0);
        expect(event.createdAt, isNotNull);
        expect(event.updatedAt, isNotNull);
      });

      test('创建全天事件', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '全天事件',
          dtStart: DateTime(2026, 1, 10),
          isAllDay: true,
        );

        expect(event.isAllDay, isTrue);
      });

      test('创建带重复规则的事件', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '每周会议',
          dtStart: DateTime(2026, 1, 10, 14, 0),
          rrule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        );

        expect(event.isRecurring, isTrue);
        expect(event.rrule, contains('WEEKLY'));
      });
    });

    group('duration', () {
      test('计算事件时长', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '测试事件',
          dtStart: DateTime(2026, 1, 10, 14, 0),
          dtEnd: DateTime(2026, 1, 10, 15, 30),
        );

        expect(event.duration, const Duration(hours: 1, minutes: 30));
      });

      test('全天事件默认时长为1天', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '全天事件',
          dtStart: DateTime(2026, 1, 10),
          isAllDay: true,
        );

        expect(event.duration, const Duration(days: 1));
      });

      test('无结束时间时默认时长为1小时', () {
        final event = EventModel.create(
          calendarId: 'calendar-1',
          summary: '测试事件',
          dtStart: DateTime(2026, 1, 10, 14, 0),
        );

        expect(event.duration, const Duration(hours: 1));
      });
    });

    group('toMap / fromMap', () {
      test('序列化和反序列化保持一致', () {
        final original = EventModel.create(
          calendarId: 'calendar-1',
          summary: '测试事件',
          description: '这是一个测试描述',
          location: '会议室 A',
          dtStart: DateTime(2026, 1, 10, 14, 0),
          dtEnd: DateTime(2026, 1, 10, 15, 0),
          isAllDay: false,
          rrule: 'FREQ=DAILY;COUNT=5',
          color: 0xFF2563EB,
          priority: 5,
          url: 'https://example.com',
        );

        final map = original.toMap();
        final restored = EventModel.fromMap(map);

        expect(restored.uid, original.uid);
        expect(restored.calendarId, original.calendarId);
        expect(restored.summary, original.summary);
        expect(restored.description, original.description);
        expect(restored.location, original.location);
        expect(restored.isAllDay, original.isAllDay);
        expect(restored.rrule, original.rrule);
        expect(restored.color, original.color);
        expect(restored.priority, original.priority);
        expect(restored.url, original.url);
        expect(restored.status, original.status);
      });

      test('序列化排除日期', () {
        final now = DateTime.now();
        final original = EventModel(
          uid: 'test-uid',
          calendarId: 'calendar-1',
          summary: '测试事件',
          dtStart: now,
          exDates: [
            DateTime(2026, 1, 5),
            DateTime(2026, 1, 10),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final map = original.toMap();
        final restored = EventModel.fromMap(map);

        expect(restored.exDates, isNotNull);
        expect(restored.exDates!.length, 2);
      });
    });

    group('copyWith', () {
      test('复制并修改部分属性', () {
        final original = EventModel.create(
          calendarId: 'calendar-1',
          summary: '原始标题',
          dtStart: DateTime(2026, 1, 10, 14, 0),
        );

        final modified = original.copyWith(
          summary: '新标题',
          location: '新地点',
        );

        expect(modified.uid, original.uid);
        expect(modified.summary, '新标题');
        expect(modified.location, '新地点');
        expect(modified.dtStart, original.dtStart);
      });
    });

    group('equality', () {
      test('相同 UID 的事件相等', () {
        final now = DateTime.now();
        final event1 = EventModel(
          uid: 'same-uid',
          calendarId: 'calendar-1',
          summary: '事件1',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        final event2 = EventModel(
          uid: 'same-uid',
          calendarId: 'calendar-2',
          summary: '事件2',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('不同 UID 的事件不相等', () {
        final now = DateTime.now();
        final event1 = EventModel(
          uid: 'uid-1',
          calendarId: 'calendar-1',
          summary: '事件',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        final event2 = EventModel(
          uid: 'uid-2',
          calendarId: 'calendar-1',
          summary: '事件',
          dtStart: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(event1, isNot(equals(event2)));
      });
    });
  });

  group('EventInstance', () {
    test('从非重复事件创建实例', () {
      final event = EventModel.create(
        calendarId: 'calendar-1',
        summary: '测试事件',
        dtStart: DateTime(2026, 1, 10, 14, 0),
        dtEnd: DateTime(2026, 1, 10, 15, 0),
      );

      final instance = EventInstance.fromEvent(event);

      expect(instance.event, event);
      expect(instance.instanceStart, event.dtStart);
      expect(instance.instanceEnd, event.dtEnd);
      expect(instance.isException, isFalse);
    });
  });
}
