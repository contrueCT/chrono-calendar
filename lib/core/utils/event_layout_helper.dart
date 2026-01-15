import '../../data/models/event_model.dart';

/// 事件布局信息
class EventLayoutInfo {
  /// 事件实例
  final EventInstance event;

  /// 列索引（0 开始）
  final int columnIndex;

  /// 总列数
  final int totalColumns;

  const EventLayoutInfo({
    required this.event,
    required this.columnIndex,
    required this.totalColumns,
  });

  /// 计算事件的相对宽度（0.0 - 1.0）
  double get widthFraction => 1.0 / totalColumns;

  /// 计算事件的左偏移比例（0.0 - 1.0）
  double get leftFraction => columnIndex / totalColumns;
}

/// 事件布局辅助类
///
/// 用于计算重叠事件的布局位置，确保同一时间段的多个事件
/// 可以并排显示而不互相覆盖。
class EventLayoutHelper {
  EventLayoutHelper._();

  /// 计算事件列表的布局信息
  ///
  /// 算法说明：
  /// 1. 按开始时间排序事件
  /// 2. 使用贪心算法将事件分配到列中
  /// 3. 每个事件尽量放在最左边的可用列
  static List<EventLayoutInfo> calculateLayout(List<EventInstance> events) {
    if (events.isEmpty) return [];

    // 按开始时间排序
    final sortedEvents = List<EventInstance>.from(events)
      ..sort((a, b) => a.instanceStart.compareTo(b.instanceStart));

    // 存储每列当前的结束时间
    final columnEndTimes = <DateTime>[];

    // 为每个事件分配列
    final eventColumns = <EventInstance, int>{};

    for (final event in sortedEvents) {
      final eventStart = event.instanceStart;

      // 找到第一个可用的列（结束时间早于或等于当前事件开始时间）
      int assignedColumn = -1;
      for (int i = 0; i < columnEndTimes.length; i++) {
        if (!columnEndTimes[i].isAfter(eventStart)) {
          assignedColumn = i;
          columnEndTimes[i] = event.instanceEnd;
          break;
        }
      }

      // 如果没有可用列，创建新列
      if (assignedColumn == -1) {
        assignedColumn = columnEndTimes.length;
        columnEndTimes.add(event.instanceEnd);
      }

      eventColumns[event] = assignedColumn;
    }

    // 计算每个事件的重叠组和总列数
    final result = <EventLayoutInfo>[];

    for (final event in sortedEvents) {
      // 找出与当前事件重叠的所有事件
      final overlappingEvents = sortedEvents.where((other) {
        return _eventsOverlap(event, other);
      }).toList();

      // 计算这组重叠事件使用的最大列数
      int maxColumn = 0;
      for (final overlapping in overlappingEvents) {
        final col = eventColumns[overlapping]!;
        if (col > maxColumn) maxColumn = col;
      }
      final totalColumns = maxColumn + 1;

      result.add(EventLayoutInfo(
        event: event,
        columnIndex: eventColumns[event]!,
        totalColumns: totalColumns,
      ));
    }

    return result;
  }

  /// 检查两个事件是否在时间上重叠
  static bool _eventsOverlap(EventInstance a, EventInstance b) {
    // 如果 a 结束时间 <= b 开始时间，不重叠
    if (!a.instanceEnd.isAfter(b.instanceStart)) return false;
    // 如果 b 结束时间 <= a 开始时间，不重叠
    if (!b.instanceEnd.isAfter(a.instanceStart)) return false;
    return true;
  }

  /// 简化版：只计算每个事件应该占用的宽度比例
  ///
  /// 返回 Map，key 是事件，value 是 (columnIndex, totalColumns)
  static Map<EventInstance, (int, int)> calculateSimpleLayout(
    List<EventInstance> events,
  ) {
    final layoutInfos = calculateLayout(events);
    return {
      for (final info in layoutInfos)
        info.event: (info.columnIndex, info.totalColumns)
    };
  }
}
