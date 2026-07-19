import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';

/// Android 平台适配设置页
///
/// 提供 Android 专属功能配置：
/// - 每日提醒
/// - 通知设置
/// - 小组件
/// - 电池优化
class AndroidSettingsPage extends ConsumerStatefulWidget {
  const AndroidSettingsPage({super.key});

  @override
  ConsumerState<AndroidSettingsPage> createState() =>
      _AndroidSettingsPageState();
}

class _AndroidSettingsPageState extends ConsumerState<AndroidSettingsPage> {
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _todoReminderEnabled = true;
  bool _batteryOptimizationExempt = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Android 设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 每日提醒 ─────────────────────────────
          const Text(
            '每日提醒',
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
                  secondary: Icon(Icons.notifications, color: theme.diaryColor.color),
                  title: const Text('每日写日记提醒'),
                  subtitle: Text(
                    _dailyReminderEnabled
                        ? '每天 ${_reminderTime.format(context)} 提醒'
                        : '已关闭',
                  ),
                  value: _dailyReminderEnabled,
                  onChanged: (value) {
                    setState(() => _dailyReminderEnabled = value);
                    if (value) {
                      _selectReminderTime(context);
                    }
                    // TODO: 注册/取消通知
                  },
                ),
                if (_dailyReminderEnabled) ...[
                  const Divider(height: 1, color: Colors.white12),
                  ListTile(
                    leading: Icon(Icons.access_time, color: theme.todoColor.color),
                    title: const Text('提醒时间'),
                    subtitle: Text(_reminderTime.format(context)),
                    trailing: const Icon(Icons.edit, color: Colors.white54),
                    onTap: () => _selectReminderTime(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 通知设置 ─────────────────────────────
          const Text(
            '通知设置',
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
                  secondary: const Icon(Icons.check_box, color: Colors.white70),
                  title: const Text('待办提醒'),
                  subtitle: const Text('待办到期时发送通知'),
                  value: _todoReminderEnabled,
                  onChanged: (value) {
                    setState(() => _todoReminderEnabled = value);
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                SwitchListTile(
                  secondary: const Icon(Icons.celebration, color: Colors.white70),
                  title: const Text('完成庆祝'),
                  subtitle: const Text('完成待办时显示庆祝通知'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 小组件 ───────────────────────────────
          const Text(
            '桌面小组件',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.widgets, color: theme.tagColor.color),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stargazer 小组件',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '在桌面显示今日待办和日记统计',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.backgroundTop,
                          theme.backgroundBottom,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '小组件预览',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '长按桌面 → 小组件 → 找到 Stargazer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 电池优化 ─────────────────────────────
          const Text(
            '电池优化',
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
              // TODO: 请求忽略电池优化
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请在系统设置中允许 Stargazer 后台运行')),
              );
            },
            child: Row(
              children: [
                Icon(
                  _batteryOptimizationExempt
                      ? Icons.battery_full
                      : Icons.battery_alert,
                  color: _batteryOptimizationExempt
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '后台运行权限',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _batteryOptimizationExempt
                            ? '已允许后台运行'
                            : '点击前往系统设置',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
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

  Future<void> _selectReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      // TODO: 重新注册通知
    }
  }
}
