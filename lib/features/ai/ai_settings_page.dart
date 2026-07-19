import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/frosted_card.dart';
import 'ai_tag_service.dart';

/// AI 设置页面
class AISettingsPage extends ConsumerStatefulWidget {
  const AISettingsPage({super.key});

  @override
  ConsumerState<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends ConsumerState<AISettingsPage> {
  final AITagService _service = AITagService();
  String _mode = AITagService.modeLocal;
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO: 加载已保存的设置
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 分析模式选择
          const Text(
            '分析模式',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: AITagService.modeLocal,
                  groupValue: _mode,
                  title: const Text('本地分析'),
                  subtitle: const Text('使用关键词匹配，无需网络'),
                  onChanged: (value) {
                    setState(() {
                      _mode = value!;
                      _service.setMode(_mode);
                    });
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                RadioListTile<String>(
                  value: AITagService.modeCloud,
                  groupValue: _mode,
                  title: const Text('云端分析'),
                  subtitle: const Text('使用 AI 模型，需要配置 API'),
                  onChanged: (value) {
                    setState(() {
                      _mode = value!;
                      _service.setMode(_mode);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 云端 API 配置
          if (_mode == AITagService.modeCloud) ...[
            const Text(
              'API 配置',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            FrostedCard(
              child: Column(
                children: [
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: '输入你的 API 密钥',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API URL',
                      hintText: 'https://api.example.com/analyze',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _service.setApiConfig(
                          _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
                          _apiUrlController.text.isEmpty ? null : _apiUrlController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('设置已保存')),
                        );
                      },
                      child: const Text('保存配置'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 功能说明
          const Text(
            '功能说明',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple.shade300),
                    const SizedBox(width: 12),
                    const Text(
                      '自动标签',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 自动分析日记内容，提取关键词作为标签\n'
                  '• 识别文本情绪，给出情绪评分\n'
                  '• 推荐相关标签，方便快速分类\n'
                  '• 本地模式使用关键词匹配\n'
                  '• 云端模式使用 AI 大模型分析',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
