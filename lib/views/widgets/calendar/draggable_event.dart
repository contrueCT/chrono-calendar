import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';

/// 拖拽模式
enum DragMode {
  /// 移动整个事件（改变开始时间）
  move,

  /// 调整顶部（改变开始时间，保持结束时间）
  resizeTop,

  /// 调整底部（改变结束时间，保持开始时间）
  resizeBottom,
}

/// 可拖拽事件组件
/// 用于周视图和日视图中的事件拖拽调整
class DraggableEventWidget extends StatefulWidget {
  /// 事件实例
  final EventInstance event;

  /// 每小时高度（像素）
  final double hourHeight;

  /// 时间轴左侧偏移
  final double leftOffset;

  /// 事件卡片右侧边距
  final double rightOffset;

  /// 拖拽完成后的回调
  final void Function(DateTime newStart, DateTime newEnd)? onDragComplete;

  /// 点击事件回调
  final VoidCallback? onTap;

  /// 是否显示详细信息
  final bool showDetails;

  /// 时间吸附粒度（分钟）
  final int snapMinutes;

  const DraggableEventWidget({
    super.key,
    required this.event,
    required this.hourHeight,
    this.leftOffset = 0,
    this.rightOffset = 0,
    this.onDragComplete,
    this.onTap,
    this.showDetails = true,
    this.snapMinutes = 15,
  });

  @override
  State<DraggableEventWidget> createState() => _DraggableEventWidgetState();
}

class _DraggableEventWidgetState extends State<DraggableEventWidget>
    with SingleTickerProviderStateMixin {
  /// 是否正在拖拽
  bool _isDragging = false;

  /// 当前拖拽模式
  DragMode _dragMode = DragMode.move;

  /// 拖拽偏移量（像素）
  double _dragDeltaY = 0;

  /// 调整大小时的高度变化
  double _heightDelta = 0;

  /// 预览时间
  DateTime? _previewStart;
  DateTime? _previewEnd;

  /// 动画控制器
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  /// 调整手柄高度
  static const double _resizeHandleHeight = 12.0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// 计算事件块的位置和高度
  double get _eventTop {
    final startMinutes =
        widget.event.instanceStart.hour * 60 + widget.event.instanceStart.minute;
    return startMinutes * widget.hourHeight / 60;
  }

  double get _eventHeight {
    final startMinutes =
        widget.event.instanceStart.hour * 60 + widget.event.instanceStart.minute;
    final endMinutes =
        widget.event.instanceEnd.hour * 60 + widget.event.instanceEnd.minute;
    final durationMinutes = endMinutes - startMinutes;
    return (durationMinutes * widget.hourHeight / 60).clamp(30.0, double.infinity);
  }

  /// 拖拽后的位置
  double get _draggedTop {
    if (_dragMode == DragMode.resizeBottom) {
      return _eventTop;
    }
    return _eventTop + _dragDeltaY;
  }

  /// 拖拽后的高度
  double get _draggedHeight {
    double height = _eventHeight;
    if (_dragMode == DragMode.resizeTop) {
      height = _eventHeight - _dragDeltaY;
    } else if (_dragMode == DragMode.resizeBottom) {
      height = _eventHeight + _heightDelta;
    }
    return height.clamp(30.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventColor = Color(widget.event.event.color ?? colorScheme.primary.value);

    return Positioned(
      left: widget.leftOffset,
      right: widget.rightOffset,
      top: _isDragging ? _draggedTop : _eventTop,
      height: _isDragging ? _draggedHeight : _eventHeight,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: _isDragging ? null : widget.onTap,
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          onLongPressEnd: _onLongPressEnd,
          child: Stack(
            children: [
              // 事件卡片主体
              _buildEventCard(eventColor, colorScheme),

              // 顶部调整手柄（拖拽时显示）
              if (_isDragging && _dragMode != DragMode.resizeBottom)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _resizeHandleHeight,
                  child: _buildResizeHandle(colorScheme, isTop: true),
                ),

              // 底部调整手柄（拖拽时显示）
              if (_isDragging && _dragMode != DragMode.resizeTop)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _resizeHandleHeight,
                  child: _buildResizeHandle(colorScheme, isTop: false),
                ),

              // 时间预览标签
              if (_isDragging && _previewStart != null)
                Positioned(
                  top: -28,
                  left: 0,
                  right: 0,
                  child: _buildTimePreview(colorScheme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Color eventColor, ColorScheme colorScheme) {
    final height = _isDragging ? _draggedHeight : _eventHeight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(_isDragging ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: eventColor.withOpacity(_isDragging ? 0.6 : 0.3),
          width: _isDragging ? 2 : 1,
        ),
        boxShadow: _isDragging
            ? [
                BoxShadow(
                  color: eventColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 左侧颜色条
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                bottomLeft: Radius.circular(7),
              ),
            ),
          ),

          // 内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    widget.event.event.summary,
                    style: TextStyle(
                      fontSize: height > 50 ? 13 : 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: height > 60 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 时间（如果高度足够且显示详情）
                  if (widget.showDetails && height > 45) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('HH:mm').format(widget.event.instanceStart)} - ${DateFormat('HH:mm').format(widget.event.instanceEnd)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  // 地点（如果高度足够）
                  if (widget.showDetails &&
                      height > 70 &&
                      widget.event.event.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.event.event.location!,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 重复图标
          if (widget.event.event.isRecurring)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.repeat,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(ColorScheme colorScheme, {required bool isTop}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePreview(ColorScheme colorScheme) {
    final startStr = DateFormat('HH:mm').format(_previewStart!);
    final endStr = _previewEnd != null ? DateFormat('HH:mm').format(_previewEnd!) : '';

    String text;
    if (_dragMode == DragMode.resizeTop) {
      text = '$startStr - ${DateFormat('HH:mm').format(widget.event.instanceEnd)}';
    } else if (_dragMode == DragMode.resizeBottom) {
      text = '${DateFormat('HH:mm').format(widget.event.instanceStart)} - $endStr';
    } else {
      text = '$startStr - $endStr';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) {
    // 触觉反馈
    HapticFeedback.mediumImpact();

    // 确定拖拽模式（根据触摸位置）
    final localY = details.localPosition.dy;
    final height = _eventHeight;

    if (localY < _resizeHandleHeight * 2) {
      _dragMode = DragMode.resizeTop;
    } else if (localY > height - _resizeHandleHeight * 2) {
      _dragMode = DragMode.resizeBottom;
    } else {
      _dragMode = DragMode.move;
    }

    setState(() {
      _isDragging = true;
      _dragDeltaY = 0;
      _heightDelta = 0;
      _updatePreviewTime();
    });

    _scaleController.forward();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      if (_dragMode == DragMode.resizeBottom) {
        _heightDelta = details.offsetFromOrigin.dy;
      } else {
        _dragDeltaY = details.offsetFromOrigin.dy;
      }
      _updatePreviewTime();
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    // 轻触觉反馈
    HapticFeedback.lightImpact();

    _scaleController.reverse();

    // 计算最终时间并回调
    if (_previewStart != null && _previewEnd != null && widget.onDragComplete != null) {
      // 验证时间有效性
      if (_previewEnd!.isAfter(_previewStart!)) {
        widget.onDragComplete!(_previewStart!, _previewEnd!);
      }
    }

    setState(() {
      _isDragging = false;
      _dragDeltaY = 0;
      _heightDelta = 0;
      _previewStart = null;
      _previewEnd = null;
    });
  }

  void _updatePreviewTime() {
    final originalStart = widget.event.instanceStart;
    final originalEnd = widget.event.instanceEnd;
    final originalDuration = originalEnd.difference(originalStart);

    // 将像素偏移转换为分钟
    int deltaMinutes = (_dragDeltaY / widget.hourHeight * 60).round();
    int heightDeltaMinutes = (_heightDelta / widget.hourHeight * 60).round();

    // 吸附到指定粒度
    deltaMinutes = (deltaMinutes / widget.snapMinutes).round() * widget.snapMinutes;
    heightDeltaMinutes =
        (heightDeltaMinutes / widget.snapMinutes).round() * widget.snapMinutes;

    DateTime newStart;
    DateTime newEnd;

    switch (_dragMode) {
      case DragMode.move:
        newStart = originalStart.add(Duration(minutes: deltaMinutes));
        newEnd = newStart.add(originalDuration);
        break;

      case DragMode.resizeTop:
        newStart = originalStart.add(Duration(minutes: deltaMinutes));
        newEnd = originalEnd;
        // 确保开始时间不晚于结束时间
        if (newStart.isAfter(newEnd.subtract(const Duration(minutes: 15)))) {
          newStart = newEnd.subtract(const Duration(minutes: 15));
        }
        break;

      case DragMode.resizeBottom:
        newStart = originalStart;
        newEnd = originalEnd.add(Duration(minutes: heightDeltaMinutes));
        // 确保结束时间不早于开始时间
        if (newEnd.isBefore(newStart.add(const Duration(minutes: 15)))) {
          newEnd = newStart.add(const Duration(minutes: 15));
        }
        break;
    }

    // 限制在当天范围内
    final dayStart = DateTime(originalStart.year, originalStart.month, originalStart.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (newStart.isBefore(dayStart)) {
      final diff = dayStart.difference(newStart);
      newStart = dayStart;
      if (_dragMode == DragMode.move) {
        newEnd = newEnd.add(diff);
      }
    }

    if (newEnd.isAfter(dayEnd)) {
      final diff = newEnd.difference(dayEnd);
      newEnd = dayEnd;
      if (_dragMode == DragMode.move) {
        newStart = newStart.subtract(diff);
        if (newStart.isBefore(dayStart)) {
          newStart = dayStart;
        }
      }
    }

    _previewStart = newStart;
    _previewEnd = newEnd;
  }
}

/// 简化版可拖拽事件（用于周视图的紧凑显示）
class CompactDraggableEvent extends StatefulWidget {
  final EventInstance event;
  final double hourHeight;
  final void Function(DateTime newStart, DateTime newEnd)? onDragComplete;
  final VoidCallback? onTap;
  final int snapMinutes;

  const CompactDraggableEvent({
    super.key,
    required this.event,
    required this.hourHeight,
    this.onDragComplete,
    this.onTap,
    this.snapMinutes = 15,
  });

  @override
  State<CompactDraggableEvent> createState() => _CompactDraggableEventState();
}

class _CompactDraggableEventState extends State<CompactDraggableEvent> {
  bool _isDragging = false;
  double _dragDeltaY = 0;
  DateTime? _previewStart;
  DateTime? _previewEnd;

  double get _eventTop {
    final startMinutes =
        widget.event.instanceStart.hour * 60 + widget.event.instanceStart.minute;
    return startMinutes * widget.hourHeight / 60;
  }

  double get _eventHeight {
    final startMinutes =
        widget.event.instanceStart.hour * 60 + widget.event.instanceStart.minute;
    final endMinutes =
        widget.event.instanceEnd.hour * 60 + widget.event.instanceEnd.minute;
    final durationMinutes = endMinutes - startMinutes;
    return (durationMinutes * widget.hourHeight / 60).clamp(20.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventColor = Color(widget.event.event.color ?? colorScheme.primary.value);

    return Positioned(
      left: 2,
      right: 2,
      top: _isDragging ? _eventTop + _dragDeltaY : _eventTop,
      height: _eventHeight,
      child: GestureDetector(
        onTap: _isDragging ? null : widget.onTap,
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 事件卡片
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    eventColor.withOpacity(_isDragging ? 0.95 : 0.85),
                    eventColor.withOpacity(_isDragging ? 0.85 : 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isDragging
                    ? [
                        BoxShadow(
                          color: eventColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: eventColor.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              transform: _isDragging
                  ? (Matrix4.identity()..scale(1.02))
                  : Matrix4.identity(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  widget.event.event.summary,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: _eventHeight > 40 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 时间预览
            if (_isDragging && _previewStart != null)
              Positioned(
                top: -22,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${DateFormat('HH:mm').format(_previewStart!)} - ${DateFormat('HH:mm').format(_previewEnd!)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onInverseSurface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = true;
      _dragDeltaY = 0;
      _updatePreviewTime();
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      _dragDeltaY = details.offsetFromOrigin.dy;
      _updatePreviewTime();
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    HapticFeedback.lightImpact();

    if (_previewStart != null && _previewEnd != null && widget.onDragComplete != null) {
      if (_previewEnd!.isAfter(_previewStart!)) {
        widget.onDragComplete!(_previewStart!, _previewEnd!);
      }
    }

    setState(() {
      _isDragging = false;
      _dragDeltaY = 0;
      _previewStart = null;
      _previewEnd = null;
    });
  }

  void _updatePreviewTime() {
    final originalStart = widget.event.instanceStart;
    final originalEnd = widget.event.instanceEnd;
    final duration = originalEnd.difference(originalStart);

    int deltaMinutes = (_dragDeltaY / widget.hourHeight * 60).round();
    deltaMinutes = (deltaMinutes / widget.snapMinutes).round() * widget.snapMinutes;

    var newStart = originalStart.add(Duration(minutes: deltaMinutes));
    var newEnd = newStart.add(duration);

    // 限制在当天范围
    final dayStart = DateTime(originalStart.year, originalStart.month, originalStart.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (newStart.isBefore(dayStart)) {
      newStart = dayStart;
      newEnd = newStart.add(duration);
    }
    if (newEnd.isAfter(dayEnd)) {
      newEnd = dayEnd;
      newStart = newEnd.subtract(duration);
    }

    _previewStart = newStart;
    _previewEnd = newEnd;
  }
}
