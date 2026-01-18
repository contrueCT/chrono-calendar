import 'package:flutter/material.dart';
import '../../../data/models/llm_config_model.dart';
import '../../../services/llm_service.dart';
import '../../../core/utils/snackbar_helper.dart';

/// LLM 设置页面
/// 管理 AI 服务配置，支持多个服务提供商
class LLMSettingsScreen extends StatefulWidget {
  const LLMSettingsScreen({super.key});

  @override
  State<LLMSettingsScreen> createState() => _LLMSettingsScreenState();
}

class _LLMSettingsScreenState extends State<LLMSettingsScreen> {
  final LLMService _llmService = LLMService();
  List<LLMConfigModel> _configs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final configs = await _llmService.getAllConfigs();
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI 设置'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddConfigDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加配置'),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_configs.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _configs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(colorScheme);
        }
        return _buildConfigCard(_configs[index - 1], colorScheme);
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 智能日程创建',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '配置 AI 服务后，可以用自然语言快速创建日程',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '已配置的服务',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '尚未配置 AI 服务',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添加一个 AI 服务配置，即可使用自然语言创建日程',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddConfigDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('添加配置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(LLMConfigModel config, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: config.isActive
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: config.isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showEditConfigDialog(context, config),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: config.isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 24,
                      color: config.isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                config.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (config.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '当前使用',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config.model,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) => _onConfigMenuSelected(value, config),
                    itemBuilder: (context) => [
                      if (!config.isActive)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 12),
                              Text('设为当前使用'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'test',
                        child: Row(
                          children: [
                            Icon(Icons.wifi_tethering, size: 20),
                            SizedBox(width: 12),
                            Text('测试连接'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                config.baseUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfigMenuSelected(String value, LLMConfigModel config) async {
    switch (value) {
      case 'activate':
        await _llmService.setActiveConfig(config.id!);
        await _loadConfigs();
        if (mounted) {
          SnackBarHelper.show(context, '已将 ${config.name} 设为当前使用');
        }
        break;
      case 'test':
        _testConnection(config);
        break;
      case 'edit':
        _showEditConfigDialog(context, config);
        break;
      case 'delete':
        _showDeleteConfirmDialog(config);
        break;
    }
  }

  Future<void> _testConnection(LLMConfigModel config) async {
    final apiKey = await _llmService.getApiKey(config.id!);
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        SnackBarHelper.showWarning(context, 'API Key 未配置');
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Text('正在测试连接...'),
            ],
          ),
        ),
      );
    }

    final result = await _llmService.testConnection(config, apiKey);

    if (mounted) {
      Navigator.pop(context); // 关闭加载对话框
      if (result.isSuccess) {
        SnackBarHelper.showSuccess(context, '连接成功: ${result.message}');
      } else {
        SnackBarHelper.showError(context, '连接失败: ${result.message}');
      }
    }
  }

  void _showDeleteConfirmDialog(LLMConfigModel config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定要删除 "${config.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _llmService.deleteConfig(config.id!);
              await _loadConfigs();
              if (mounted) {
                SnackBarHelper.show(context, '配置已删除');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddConfigDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConfigEditSheet(
        onSaved: () {
          _loadConfigs();
        },
      ),
    );
  }

  void _showEditConfigDialog(BuildContext context, LLMConfigModel config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConfigEditSheet(
        config: config,
        onSaved: () {
          _loadConfigs();
        },
      ),
    );
  }
}

/// 配置编辑底部弹窗
class _ConfigEditSheet extends StatefulWidget {
  final LLMConfigModel? config;
  final VoidCallback onSaved;

  const _ConfigEditSheet({
    this.config,
    required this.onSaved,
  });

  @override
  State<_ConfigEditSheet> createState() => _ConfigEditSheetState();
}

class _ConfigEditSheetState extends State<_ConfigEditSheet> {
  final LLMService _llmService = LLMService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;

  LLMProvider? _selectedProvider;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  bool get _isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');
    _baseUrlController = TextEditingController(text: widget.config?.baseUrl ?? '');
    _modelController = TextEditingController(text: widget.config?.model ?? '');
    _apiKeyController = TextEditingController();

    if (_isEditing) {
      _loadApiKey();
    }
  }

  Future<void> _loadApiKey() async {
    if (widget.config?.id != null) {
      final apiKey = await _llmService.getApiKey(widget.config!.id!);
      if (apiKey != null && mounted) {
        setState(() {
          _apiKeyController.text = apiKey;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onProviderSelected(LLMProvider provider) {
    setState(() {
      _selectedProvider = provider;
      if (provider.name != '自定义') {
        _nameController.text = provider.name;
        _baseUrlController.text = provider.baseUrl;
        if (provider.models.isNotEmpty) {
          _modelController.text = provider.models.first;
        }
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final testConfig = LLMConfigModel(
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      createdAt: DateTime.now(),
    );

    final result = await _llmService.testConnection(
      testConfig,
      _apiKeyController.text.trim(),
    );

    setState(() => _isTesting = false);

    if (mounted) {
      if (result.isSuccess) {
        SnackBarHelper.showSuccess(context, '连接成功: ${result.message}');
      } else {
        SnackBarHelper.showError(context, '连接失败: ${result.message}');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isNewConfig = !_isEditing;

      final config = LLMConfigModel(
        id: widget.config?.id,
        name: _nameController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        isActive: widget.config?.isActive ?? false,
        createdAt: widget.config?.createdAt ?? DateTime.now(),
      );

      final configId = await _llmService.saveConfig(config, _apiKeyController.text.trim());

      // 新配置自动启用
      if (isNewConfig) {
        await _llmService.setActiveConfig(configId);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        SnackBarHelper.show(
          context,
          isNewConfig ? '配置已添加并启用' : '配置已更新',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, '保存失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? '编辑配置' : '添加配置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // 表单
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 预设选择（仅新建时显示）
                      if (!_isEditing) ...[
                        Text(
                          '选择服务商',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: LLMProvider.presets.map((provider) {
                            final isSelected =
                                _selectedProvider?.name == provider.name;
                            return ChoiceChip(
                              label: Text(provider.name),
                              selected: isSelected,
                              onSelected: (_) => _onProviderSelected(provider),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 配置名称
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '配置名称',
                          hintText: '例如：OpenAI、DeepSeek',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入配置名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // API 地址
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API 地址',
                          hintText: 'https://api.openai.com/v1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入 API 地址';
                          }
                          if (!value.startsWith('http://') &&
                              !value.startsWith('https://')) {
                            return '请输入有效的 URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 模型名称
                      TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: '模型名称',
                          hintText: 'gpt-4o-mini',
                          border: const OutlineInputBorder(),
                          suffixIcon: _selectedProvider != null &&
                                  _selectedProvider!.models.isNotEmpty
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (model) {
                                    _modelController.text = model;
                                  },
                                  itemBuilder: (context) => _selectedProvider!
                                      .models
                                      .map((m) => PopupMenuItem(
                                            value: m,
                                            child: Text(m),
                                          ))
                                      .toList(),
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入模型名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // API Key
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'sk-...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscureApiKey = !_obscureApiKey);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入 API Key';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'API Key 将被安全加密存储在本地',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 测试连接按钮
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: Text(_isTesting ? '测试中...' : '测试连接'),
                      ),
                      const SizedBox(height: 16),

                      // 保存按钮
                      FilledButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEditing ? '保存' : '添加'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
