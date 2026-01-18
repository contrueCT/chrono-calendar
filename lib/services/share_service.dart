import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import '../data/models/event_model.dart';
import '../data/models/share_template.dart';
import '../core/utils/lunar_utils.dart';

/// 分享服务 - 生成精美的事件分享图片并分享
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// 分享卡片的 GlobalKey，用于渲染图片
  final GlobalKey shareCardKey = GlobalKey();

  /// 生成事件分享图片
  /// 返回生成的图片文件，如果失败返回 null
  Future<File?> generateShareImage(GlobalKey repaintKey) async {
    try {
      // 获取 RenderRepaintBoundary
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('无法获取 RenderRepaintBoundary');
        return null;
      }

      // 渲染为图片（3倍分辨率，确保清晰）
      final image = await boundary.toImage(pixelRatio: 3.0);

      // 转换为字节数据
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('无法转换图片为字节数据');
        return null;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/event_share_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint('生成分享图片失败: $e');
      return null;
    }
  }

  /// 分享事件图片
  Future<void> shareEventImage(File imageFile, {String? text}) async {
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: text,
      );
    } catch (e) {
      debugPrint('分享图片失败: $e');
    }
  }

  /// 保存图片到相册
  /// 返回 true 表示保存成功
  Future<bool> saveImageToGallery(File imageFile) async {
    try {
      await Gal.putImage(imageFile.path);
      return true;
    } catch (e) {
      debugPrint('保存图片到相册失败: $e');
      return false;
    }
  }

  /// 清理临时分享图片
  Future<void> cleanupTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      final files = dir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('event_share_')) {
          // 只删除超过1小时的旧文件
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified).inHours > 1) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('清理临时图片失败: $e');
    }
  }
}

/// 分享卡片 Widget - 用于渲染分享图片
class ShareCardWidget extends StatelessWidget {
  /// 事件数据
  final EventModel event;

  /// 事件实例的开始时间（用于重复事件）
  final DateTime instanceStart;

  /// 事件实例的结束时间
  final DateTime instanceEnd;

  /// 分享模板
  final ShareTemplate template;

  /// 是否显示天气（可选）
  final String? weatherText;

  /// 是否显示农历
  final bool showLunar;

  const ShareCardWidget({
    super.key,
    required this.event,
    required this.instanceStart,
    required this.instanceEnd,
    required this.template,
    this.weatherText,
    this.showLunar = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: template.gradient,
          // borderRadius 由外层 ClipRRect 处理，确保圆角外区域为透明
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部装饰线
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: template.textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // 日期
          Text(
            DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(instanceStart),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: template.secondaryTextColor,
            ),
          ),

          // 农历
          if (showLunar) ...[
            const SizedBox(height: 4),
            Text(
              LunarUtils.getFullLunarString(instanceStart),
              style: TextStyle(
                fontSize: 13,
                color: template.secondaryTextColor.withOpacity(0.8),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 事件标题
          Text(
            event.summary,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: template.textColor,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 20),

          // 时间
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            text: event.isAllDay
                ? '全天'
                : '${DateFormat('HH:mm').format(instanceStart)} - '
                    '${DateFormat('HH:mm').format(instanceEnd)}',
          ),

          // 地点
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              text: event.location!,
              maxLines: 2,
            ),
          ],

          // 描述（可选，截取前50个字符）
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.notes_rounded,
              text: event.description!.length > 50
                  ? '${event.description!.substring(0, 50)}...'
                  : event.description!,
              maxLines: 2,
            ),
          ],

          // 天气（可选）
          if (weatherText != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.cloud_outlined,
              text: weatherText!,
            ),
          ],

          const SizedBox(height: 32),

          // 分隔线
          Container(
            height: 1,
            color: template.textColor.withOpacity(0.1),
          ),

          const SizedBox(height: 16),

          // 底部水印
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created with Chrono',
                style: TextStyle(
                  fontSize: 12,
                  color: template.secondaryTextColor.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: template.iconColor.withOpacity(0.5),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: template.iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: template.iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: template.textColor,
                height: 1.4,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// 倒计时分享卡片 Widget
class CountdownShareCardWidget extends StatelessWidget {
  /// 倒计时标题
  final String title;

  /// 目标日期
  final DateTime targetDate;

  /// 剩余天数
  final int daysRemaining;

  /// 是否为纪念日（已过去）
  final bool isAnniversary;

  /// 分享模板
  final ShareTemplate template;

  const CountdownShareCardWidget({
    super.key,
    required this.title,
    required this.targetDate,
    required this.daysRemaining,
    required this.isAnniversary,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: template.gradient,
          // borderRadius 由外层 ClipRRect 处理，确保圆角外区域为透明
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 标题
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: template.textColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 大号天数
          Text(
            daysRemaining.abs().toString(),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: template.textColor,
              height: 1,
            ),
          ),

          const SizedBox(height: 8),

          // 天数说明
          Text(
            isAnniversary ? '天' : '天后',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: template.secondaryTextColor,
            ),
          ),

          const SizedBox(height: 24),

          // 目标日期
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: template.textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('yyyy年M月d日').format(targetDate),
              style: TextStyle(
                fontSize: 14,
                color: template.textColor,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 底部水印
          Text(
            'Created with Chrono',
            style: TextStyle(
              fontSize: 12,
              color: template.secondaryTextColor.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
