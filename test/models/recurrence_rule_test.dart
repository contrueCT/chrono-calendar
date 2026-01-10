import 'package:flutter_test/flutter_test.dart';
import 'package:chrono_calendar/data/models/recurrence_rule.dart';
import 'package:chrono_calendar/core/utils/rrule_parser.dart';

void main() {
  group('RecurrenceRule', () {
    group('fromRRuleString', () {
      test('解析简单的每日规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY');
        expect(rule.frequency, Frequency.daily);
        expect(rule.interval, 1);
        expect(rule.count, isNull);
        expect(rule.until, isNull);
      });

      test('解析带间隔的每日规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY;INTERVAL=2');
        expect(rule.frequency, Frequency.daily);
        expect(rule.interval, 2);
      });

      test('解析带次数限制的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY;COUNT=10');
        expect(rule.frequency, Frequency.daily);
        expect(rule.count, 10);
      });

      test('解析带结束日期的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=DAILY;UNTIL=20261231T235959Z');
        expect(rule.frequency, Frequency.daily);
        expect(rule.until, isNotNull);
        expect(rule.until!.year, 2026);
        expect(rule.until!.month, 12);
        expect(rule.until!.day, 31);
      });

      test('解析每周规则带 BYDAY', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=WEEKLY;BYDAY=MO,WE,FR');
        expect(rule.frequency, Frequency.weekly);
        expect(rule.byDay, isNotNull);
        expect(rule.byDay!.length, 3);
        expect(rule.byDay, contains(WeekDay.mo));
        expect(rule.byDay, contains(WeekDay.we));
        expect(rule.byDay, contains(WeekDay.fr));
      });

      test('解析每月规则带 BYMONTHDAY', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYMONTHDAY=1,15');
        expect(rule.frequency, Frequency.monthly);
        expect(rule.byMonthDay, isNotNull);
        expect(rule.byMonthDay!.length, 2);
        expect(rule.byMonthDay, contains(1));
        expect(rule.byMonthDay, contains(15));
      });

      test('解析每月规则带位置的 BYDAY', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYDAY=1MO');
        expect(rule.frequency, Frequency.monthly);
        expect(rule.byDayRules, isNotNull);
        expect(rule.byDayRules!.length, 1);
        expect(rule.byDayRules!.first.position, 1);
        expect(rule.byDayRules!.first.weekDay, WeekDay.mo);
      });

      test('解析每月最后一个周五', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYDAY=-1FR');
        expect(rule.frequency, Frequency.monthly);
        expect(rule.byDayRules, isNotNull);
        expect(rule.byDayRules!.first.position, -1);
        expect(rule.byDayRules!.first.weekDay, WeekDay.fr);
      });

      test('解析每年规则带 BYMONTH', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=YEARLY;BYMONTH=3,6,9,12');
        expect(rule.frequency, Frequency.yearly);
        expect(rule.byMonth, isNotNull);
        expect(rule.byMonth!.length, 4);
      });

      test('解析带 WKST 的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=WEEKLY;WKST=SU');
        expect(rule.weekStart, WeekDay.su);
      });

      test('解析带 BYSETPOS 的规则', () {
        final rule = RecurrenceRule.fromRRuleString('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1');
        expect(rule.bySetPos, isNotNull);
        expect(rule.bySetPos!.first, -1);
      });
    });

    group('toRRuleString', () {
      test('生成简单的每日规则', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        expect(rule.toRRuleString(), 'FREQ=DAILY');
      });

      test('生成带间隔的规则', () {
        final rule = RecurrenceRule(frequency: Frequency.weekly, interval: 2);
        expect(rule.toRRuleString(), 'FREQ=WEEKLY;INTERVAL=2');
      });

      test('生成带 BYDAY 的规则', () {
        final rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.mo, WeekDay.fr],
        );
        expect(rule.toRRuleString(), 'FREQ=WEEKLY;BYDAY=MO,FR');
      });

      test('生成带位置 BYDAY 的规则', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byDayRules: [ByDayRule(position: 1, weekDay: WeekDay.mo)],
        );
        expect(rule.toRRuleString(), 'FREQ=MONTHLY;BYDAY=1MO');
      });

      test('往返解析保持一致', () {
        const original = 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10';
        final rule = RecurrenceRule.fromRRuleString(original);
        final generated = rule.toRRuleString();
        final reparsed = RecurrenceRule.fromRRuleString(generated);

        expect(reparsed.frequency, rule.frequency);
        expect(reparsed.interval, rule.interval);
        expect(reparsed.count, rule.count);
        expect(reparsed.byDay?.length, rule.byDay?.length);
      });
    });

    group('description', () {
      test('每天的描述', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        expect(rule.description, '每天');
      });

      test('每2天的描述', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, interval: 2);
        expect(rule.description, '每 2 天');
      });

      test('每周一三五的描述', () {
        final rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.mo, WeekDay.we, WeekDay.fr],
        );
        expect(rule.description, contains('周一'));
        expect(rule.description, contains('周三'));
        expect(rule.description, contains('周五'));
      });

      test('每月第一个周一的描述', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byDayRules: [ByDayRule(position: 1, weekDay: WeekDay.mo)],
        );
        expect(rule.description, contains('第一个周一'));
      });

      test('带次数限制的描述', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, count: 10);
        expect(rule.description, contains('10 次'));
      });
    });
  });

  group('RRuleParser', () {
    group('getOccurrences', () {
      test('每日规则生成正确的日期', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        final eventStart = DateTime(2026, 1, 1, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 1, 5);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        expect(occurrences.length, 4);
        expect(occurrences[0], DateTime(2026, 1, 1, 9, 0));
        expect(occurrences[1], DateTime(2026, 1, 2, 9, 0));
        expect(occurrences[2], DateTime(2026, 1, 3, 9, 0));
        expect(occurrences[3], DateTime(2026, 1, 4, 9, 0));
      });

      test('每周规则生成正确的日期', () {
        final rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byDay: [WeekDay.mo, WeekDay.fr],
        );
        final eventStart = DateTime(2026, 1, 5, 9, 0); // 周一
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 1, 15);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        // 1/5 周一, 1/9 周五, 1/12 周一
        expect(occurrences.length, greaterThanOrEqualTo(3));
      });

      test('带 COUNT 限制的规则', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, count: 3);
        final eventStart = DateTime(2026, 1, 1, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 12, 31);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        expect(occurrences.length, 3);
      });

      test('带 UNTIL 限制的规则', () {
        final rule = RecurrenceRule(
          frequency: Frequency.daily,
          until: DateTime(2026, 1, 3),
        );
        final eventStart = DateTime(2026, 1, 1, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 12, 31);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        expect(occurrences.length, 3);
      });

      test('排除日期生效', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        final eventStart = DateTime(2026, 1, 1, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 1, 5);
        final exDates = [DateTime(2026, 1, 2), DateTime(2026, 1, 4)];

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
          exDates: exDates,
        );

        expect(occurrences.length, 2);
        expect(occurrences.any((d) => d.day == 2), isFalse);
        expect(occurrences.any((d) => d.day == 4), isFalse);
      });

      test('每月第一个周一', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byDayRules: [ByDayRule(position: 1, weekDay: WeekDay.mo)],
        );
        final eventStart = DateTime(2026, 1, 5, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 4, 1);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        expect(occurrences.length, 3);
        // 验证都是周一
        for (final occ in occurrences) {
          expect(occ.weekday, DateTime.monday);
        }
      });

      test('每月最后一个周五', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byDayRules: [ByDayRule(position: -1, weekDay: WeekDay.fr)],
        );
        final eventStart = DateTime(2026, 1, 30, 9, 0);
        final rangeStart = DateTime(2026, 1, 1);
        final rangeEnd = DateTime(2026, 4, 1);

        final occurrences = RRuleParser.getOccurrences(
          rule,
          eventStart,
          rangeStart,
          rangeEnd,
        );

        expect(occurrences.length, 3);
        // 验证都是周五
        for (final occ in occurrences) {
          expect(occ.weekday, DateTime.friday);
        }
      });
    });
  });

  group('RecurrencePresets', () {
    test('weekdays 创建工作日规则', () {
      final rule = RecurrencePresets.weekdays();
      expect(rule.frequency, Frequency.weekly);
      expect(rule.byDay?.length, 5);
      expect(rule.byDay, contains(WeekDay.mo));
      expect(rule.byDay, contains(WeekDay.fr));
      expect(rule.byDay?.contains(WeekDay.sa), isFalse);
      expect(rule.byDay?.contains(WeekDay.su), isFalse);
    });

    test('monthlyByWeekDay 创建每月第N个星期几的规则', () {
      final rule = RecurrencePresets.monthlyByWeekDay(
        position: -1,
        weekDay: WeekDay.fr,
      );
      expect(rule.frequency, Frequency.monthly);
      expect(rule.byDayRules?.first.position, -1);
      expect(rule.byDayRules?.first.weekDay, WeekDay.fr);
    });
  });
}
