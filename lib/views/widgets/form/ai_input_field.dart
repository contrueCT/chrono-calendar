import 'package:flutter/material.dart';
import '../../../data/models/llm_config_model.dart';
import '../../../services/llm_service.dart';

/// AI 智能输入组件
/// 可折叠的自然语言输入框，用于快速创建日程
class AIInputField extends StatefulWidget {
  /// 解析成功后的回调，返回解析结果
  final void Function(ParsedEventDraft draft) onParsed;

  /// 是否默认展开
  final bool initiallyExpanded;

  const AIInputField({
    super.key,
    required this.onParsed,
    this.initiallyExpanded = false,
  });

  @override
  State<AIInputField> createState() => _AIInputFieldState();
}

class _AIInputFieldState extends State<AIInputField>
    with SingleTickerProviderStateMixin {
  final LLMService _llmService = LLMService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  bool _isLoading = false;
  bool _hasAIConfig = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    _checkAIConfig();
  }

  Future<void> _checkAIConfig() async {
    final hasConfig = await _llmService.hasActiveConfig();
    if (mounted) {
      setState(() {
        _hasAIConfig = hasConfig;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        // 展开后聚焦输入框
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      } else {
        _animationController.reverse();
        _focusNode.unfocus();
      }
    });
  }

  Future<void> _parseInput() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = '请输入内容');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _llmService.parseNaturalLanguage(input);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && result.draft != null) {
      if (result.draft!.isValid) {
        widget.onParsed(result.draft!);
        _inputController.clear();
        // 解析成功后收起
        _toggleExpanded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 解析成功，已填充表单'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _errorMessage = '解析结果无效，请补充更多信息');
      }
    } else {
      setState(() => _errorMessage = result.errorMessage ?? '解析失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant,
          width: _isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部（可点击展开/收起）
          InkWell(
            onTap: _hasAIConfig ? _toggleExpanded : _showNoConfigHint,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hasAIConfig
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: _hasAIConfig
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 智能创建',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _hasAIConfig ? '用自然语言描述日程' : '点击配置 AI 服务',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 展开的内容
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 输入框
                  TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: '例如：明天下午3点在会议室开项目会，提前15分钟提醒',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    onSubmitted: (_) => _parseInput(),
                  ),
                  // 错误提示
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 底部按钮
                  Row(
                    children: [
                      // 示例提示
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildExampleChip('明天下午开会', colorScheme),
                            _buildExampleChip('周五晚上聚餐', colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 解析按钮
                      FilledButton(
                        onPressed: _isLoading ? null : _parseInput,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 18),
                                  SizedBox(width: 6),
                                  Text('解析'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        _inputController.text = text;
        _parseInput();
      },
      child: Chip(
        label: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showNoConfigHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('请先在设置中配置 AI 服务'),
        action: SnackBarAction(
          label: '去设置',
          onPressed: () {
            Navigator.of(context).pushNamed('/settings/llm');
          },
        ),
      ),
    );
  }
}
