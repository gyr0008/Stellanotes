import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';

/// Windows 平台适配设置页
///
/// 提供 Windows 专属功能配置：
/// - 系统托盘
/// - 开机自启
/// - 全局快捷键
/// - 窗口行为
class WindowsSettingsPage extends ConsumerStatefulWidget {
  const WindowsSettingsPage({super.key});

  @override
  ConsumerState<WindowsSettingsPage> createState() =>
      _WindowsSettingsPageState();
}

class _WindowsSettingsPageState extends ConsumerState<WindowsSettingsPage> {
  bool _minimizeToTray = false;
  bool _startWithWindows = false;
  bool _globalShortcutEnabled = false;
  String _globalShortcut = 'Ctrl+Shift+S';
  String _windowBehavior = 'remember'; // remember / maximize / normal

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Windows 设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 系统托盘 ─────────────────────────────
          const Text(
            '系统托盘',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(Icons.widgets, color: theme.diaryColor.color),
              title: const Text('最小化到系统托盘'),
              subtitle: const Text('关闭窗口时最小化到托盘而非退出'),
              value: _minimizeToTray,
              onChanged: (value) {
                setState(() => _minimizeToTray = value);
                // TODO: 保存设置并应用
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── 开机自启 ─────────────────────────────
          const Text(
            '启动',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(Icons.power_settings_new, color: theme.todoColor.color),
              title: const Text('开机自动启动'),
              subtitle: const Text('登录 Windows 时自动启动 Stargazer'),
              value: _startWithWindows,
              onChanged: (value) {
                setState(() => _startWithWindows = value);
                // TODO: 注册/取消注册启动项
              },
            ),
          ),
          const SizedBox(height: 24),

          // ─── 全局快捷键 ───────────────────────────
          const Text(
            '全局快捷键',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.keyboard, color: theme.tagColor.color),
                  title: const Text('启用全局快捷键'),
                  subtitle: const Text('在任意界面快速唤起 Stargazer'),
                  value: _globalShortcutEnabled,
                  onChanged: (value) {
                    setState(() => _globalShortcutEnabled = value);
                    // TODO: 注册/取消注册全局快捷键
                  },
                ),
                if (_globalShortcutEnabled) ...[
                  const Divider(height: 1, color: Colors.white12),
                  ListTile(
                    title: const Text('快捷键组合'),
                    subtitle: Text(
                      _globalShortcut,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.white54),
                    onTap: () => _editShortcut(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 窗口行为 ─────────────────────────────
          const Text(
            '窗口行为',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'remember',
                  groupValue: _windowBehavior,
                  title: const Text('记住上次窗口大小'),
                  subtitle: const Text('恢复上次关闭时的窗口状态'),
                  onChanged: (value) {
                    setState(() => _windowBehavior = value!);
                  },
                ),
                RadioListTile<String>(
                  value: 'maximize',
                  groupValue: _windowBehavior,
                  title: const Text('始终最大化'),
                  subtitle: const Text('启动时自动最大化窗口'),
                  onChanged: (value) {
                    setState(() => _windowBehavior = value!);
                  },
                ),
                RadioListTile<String>(
                  value: 'normal',
                  groupValue: _windowBehavior,
                  title: const Text('默认大小'),
                  subtitle: const Text('使用默认窗口大小 (1280x720)'),
                  onChanged: (value) {
                    setState(() => _windowBehavior = value!);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 文件关联 ─────────────────────────────
          const Text(
            '文件关联',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FrostedCard(
            effect: theme.glassEffect,
            onTap: () {
              // TODO: 注册 .md 文件关联
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件关联功能开发中')),
              );
            },
            child: Row(
              children: [
                Icon(Icons.description, color: theme.diaryColor.color),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '关联 .md 文件',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '双击 Markdown 文件用 Stargazer 打开',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editShortcut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置全局快捷键'),
        content: const Text(
          '请按下你想要的快捷键组合。\n\n例如：Ctrl+Shift+S',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _globalShortcut = 'Ctrl+Shift+D');
              Navigator.pop(context);
            },
            child: const Text('使用 Ctrl+Shift+D'),
          ),
        ],
      ),
    );
  }
}
