import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/countdown_model.dart';
import '../../../data/models/share_template.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../services/share_service.dart';

/// 倒计时分享页面 - 预览并分享倒计时卡片
class CountdownShareScreen extends StatefulWidget {
  /// 倒计时数据
  final CountdownModel countdown;

  const CountdownShareScreen({
    super.key,
    required this.countdown,
  });

  @override
  State<CountdownShareScreen> createState() => _CountdownShareScreenState();
}

class _CountdownShareScreenState extends State<CountdownShareScreen> {
  final ShareService _shareService = ShareService();
  final GlobalKey _repaintKey = GlobalKey();

  ShareTemplate _selectedTemplate = ShareTemplate.light;
  bool _showLunar = true;
  bool _showCategoryIcon = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('分享倒计时'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 分享按钮
          _isGenerating
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  tooltip: '分享',
                ),
        ],
      ),
      body: Column(
        children: [
          // 预览区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: CountdownShareCardWidget(
                    countdown: widget.countdown,
                    template: _selectedTemplate,
                    showLunar: _showLunar,
                    showCategoryIcon: _showCategoryIcon,
                  ),
                ),
              ),
            ),
          ),

          // 底部选项区域
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示条
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 模板选择
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择样式',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTemplateSelector(colorScheme),
                      ],
                    ),
                  ),

                  // 显示选项
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        // 农历开关
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text('农历', style: theme.textTheme.bodyMedium),
                              const Spacer(),
                              Switch(
                                value: _showLunar,
                                onChanged: (value) {
                                  setState(() => _showLunar = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 图标开关
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text('图标', style: theme.textTheme.bodyMedium),
                              const Spacer(),
                              Switch(
                                value: _showCategoryIcon,
                                onChanged: (value) {
                                  setState(() => _showCategoryIcon = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 保存和分享按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // 保存按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGenerating ? null : _handleSaveToGallery,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('保存图片'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 分享按钮
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isGenerating ? null : _handleShare,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.share),
                            label: Text(_isGenerating ? '生成中...' : '分享图片'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建模板选择器
  Widget _buildTemplateSelector(ColorScheme colorScheme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ShareTemplate.presets.length,
        itemBuilder: (context, index) {
          final template = ShareTemplate.presets[index];
          final isSelected = template == _selectedTemplate;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTemplate = template;
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(
                right: index < ShareTemplate.presets.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                gradient: template.gradient,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: colorScheme.primary,
                        width: 3,
                      )
                    : null,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    template.icon ?? Icons.palette,
                    color: template.textColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: template.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 处理保存到相册
  Future<void> _handleSaveToGallery() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      // 等待一帧确保 Widget 已渲染
      await Future.delayed(const Duration(milliseconds: 100));

      // 生成图片
      final imageFile = await _shareService.generateShareImage(_repaintKey);

      if (imageFile != null) {
        // 保存到相册
        final success = await _shareService.saveImageToGallery(imageFile);

        if (mounted) {
          if (success) {
            SnackBarHelper.show(context, '图片已保存到相册');
          } else {
            SnackBarHelper.showError(context, '保存失败，请检查相册权限');
          }
        }

        // 清理旧的临时文件
        _shareService.cleanupTempImages();
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, '生成图片失败，请重试');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, '保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// 处理分享
  Future<void> _handleShare() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      // 等待一帧确保 Widget 已渲染
      await Future.delayed(const Duration(milliseconds: 100));

      // 生成图片
      final imageFile = await _shareService.generateShareImage(_repaintKey);

      if (imageFile != null) {
        // 分享图片
        await _shareService.shareEventImage(
          imageFile,
          text: widget.countdown.title,
        );

        // 清理旧的临时文件
        _shareService.cleanupTempImages();
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, '生成图片失败，请重试');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, '分享失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}
