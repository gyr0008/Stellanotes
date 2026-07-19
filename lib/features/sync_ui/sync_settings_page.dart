import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_plugin.dart';
import '../../core/sync/git_sync_plugin.dart';
import '../../core/sync/webdav_sync_plugin.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/markdown_vault.dart';
import '../../core/storage/git_repo_manager.dart';
import '../providers/sync_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../core/theme/theme_provider.dart';
import '../shared/windows_settings_page.dart';
import '../shared/android_settings_page.dart';
import '../search/quick_capture_service.dart';

/// 同步设置主页
class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final syncState = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('同步设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 同步状态卡片 ────────────────────────────
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _getSyncStateIcon(syncState.state),
                      color: _getSyncStateColor(syncState.state),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSyncStateText(syncState.state),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (syncState.message != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                syncState.message!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (syncState.lastSyncedAt != null)
                      Text(
                        _formatTime(syncState.lastSyncedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
                if (syncState.conflicts.isNotEmpty) ...[
                  const Divider(height: 24, color: Colors.white12),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${syncState.conflicts.length} 个冲突待解决',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showConflictResolution(context, ref),
                        child: const Text('去解决'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ─── 同步方式列表 ────────────────────────────
          const Text(
            '同步方式',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // GitHub / Git 同步
          _buildSyncMethodCard(
            context,
            ref,
            icon: Icons.cloud_outlined,
            title: 'GitHub / Git 同步',
            subtitle: '通过 Git 远程仓库同步',
            connected: false, // TODO: 从插件状态读取
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GitSyncConfigPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // WebDAV 同步
          _buildSyncMethodCard(
            context,
            ref,
            icon: Icons.storage_outlined,
            title: 'WebDAV 同步',
            subtitle: 'NAS / Nextcloud / AList',
            connected: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WebDAVSyncConfigPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 自建服务器
          _buildSyncMethodCard(
            context,
            ref,
            icon: Icons.dns_outlined,
            title: '自建服务器',
            subtitle: 'REST API 同步（开发中）',
            connected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('自建服务器同步功能开发中')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ─── 同步设置 ───────────────────────────────
          const Text(
            '同步设置',
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
                  secondary: const Icon(Icons.sync, color: Colors.white70),
                  title: const Text('自动同步'),
                  subtitle: const Text('每隔一段时间自动同步'),
                  value: false, // TODO: 从设置读取
                  onChanged: (value) {
                    // TODO: 保存设置
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.white70),
                  title: const Text('自动同步间隔'),
                  subtitle: const Text('每 30 分钟'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    _showSyncIntervalDialog(context);
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                SwitchListTile(
                  secondary: const Icon(Icons.commit, color: Colors.white70),
                  title: const Text('自动 Git 提交'),
                  subtitle: const Text('每次修改后自动提交到本地仓库'),
                  value: true, // TODO: 从设置读取
                  onChanged: (value) {
                    // TODO: 保存设置
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── 手动操作 ───────────────────────────────
          const Text(
            '手动操作',
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
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.white70),
                  title: const Text('立即推送'),
                  subtitle: const Text('将本地变更推送到远程'),
                  onTap: () => _manualPush(context, ref),
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white70),
                  title: const Text('立即拉取'),
                  subtitle: const Text('从远程获取最新变更'),
                  onTap: () => _manualPull(context, ref),
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.sync_alt, color: Colors.white70),
                  title: const Text('立即同步'),
                  subtitle: const Text('拉取 + 合并 + 推送'),
                  onTap: () => _manualSync(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── 平台设置 ───────────────────────────────
          const Text(
            '平台设置',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (defaultTargetPlatform == TargetPlatform.windows)
            _buildPlatformCard(
              context,
              ref,
              icon: Icons.desktop_windows_outlined,
              title: 'Windows 设置',
              subtitle: '系统托盘、开机自启、全局快捷键',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WindowsSettingsPage(),
                ),
              ),
            ),
          if (defaultTargetPlatform == TargetPlatform.android)
            _buildPlatformCard(
              context,
              ref,
              icon: Icons.phone_android_outlined,
              title: 'Android 设置',
              subtitle: '通知提醒、桌面小组件、电池优化',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AndroidSettingsPage(),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ─── 新功能 ───────────────────────────────
          const Text(
            '新功能',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.search,
            title: '搜索',
            subtitle: '全文搜索日记、待办、标签',
            route: '/search',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.flash_on,
            title: '快速捕获',
            subtitle: '快速记录想法和待办',
            onTap: () => showQuickCaptureDialog(context),
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.edit_document,
            title: 'Markdown 编辑器',
            subtitle: '实时预览的 Markdown 编辑器',
            route: '/journal/markdown-editor',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.hourglass_empty,
            title: '时间旅行',
            subtitle: '回顾历史星空演变',
            route: '/starmap/time-travel',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.photo_library,
            title: '星空画廊',
            subtitle: '每日星空壁纸',
            route: '/starmap/wallpaper-gallery',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.constellation,
            title: '星座发现',
            subtitle: '自动聚类你的记忆',
            route: '/starmap/constellation-naming',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.palette,
            title: '星尘调色盘',
            subtitle: '自定义粒子颜色',
            route: '/settings/particle-colors',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.music_note,
            title: '声音景观',
            subtitle: '沉浸式环境音',
            route: '/starmap/soundscape',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.download,
            title: '数据导出',
            subtitle: '导出为 JSON/Markdown/HTML',
            route: '/settings/data-export',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            ref,
            icon: Icons.system_update,
            title: '自动更新',
            subtitle: '应用内检查和安装新版本',
            route: '/settings/auto-update',
          ),
        ],
      ),
    );
  }

  Widget _buildSyncMethodCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool connected,
    required VoidCallback onTap,
  }) {
    final theme = ref.watch(appThemeProvider);
    return FrostedCard(
      effect: theme.glassEffect,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: connected
                  ? theme.diaryColor.color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: connected ? theme.diaryColor.color : Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '已连接',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = ref.watch(appThemeProvider);
    return FrostedCard(
      effect: theme.glassEffect,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.todoColor.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.todoColor.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? route,
    VoidCallback? onTap,
  }) {
    final theme = ref.watch(appThemeProvider);
    return FrostedCard(
      effect: theme.glassEffect,
      onTap: onTap ?? () {
        if (route != null) {
          context.push(route);
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.tagColor.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.tagColor.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  IconData _getSyncStateIcon(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return Icons.sync;
      case SyncState.synced:
        return Icons.check_circle;
      case SyncState.conflict:
        return Icons.warning_amber;
      case SyncState.error:
        return Icons.error;
      case SyncState.offline:
        return Icons.cloud_off;
      case SyncState.idle:
        return Icons.cloud_outlined;
    }
  }

  Color _getSyncStateColor(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return Colors.blue;
      case SyncState.synced:
        return Colors.green;
      case SyncState.conflict:
        return Colors.orange;
      case SyncState.error:
        return Colors.red;
      case SyncState.offline:
        return Colors.grey;
      case SyncState.idle:
        return Colors.white54;
    }
  }

  String _getSyncStateText(SyncState state) {
    switch (state) {
      case SyncState.syncing:
        return '同步中...';
      case SyncState.synced:
        return '已同步';
      case SyncState.conflict:
        return '存在冲突';
      case SyncState.error:
        return '同步出错';
      case SyncState.offline:
        return '离线';
      case SyncState.idle:
        return '等待同步';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}/${time.day}';
  }

  void _showConflictResolution(BuildContext context, WidgetRef ref) {
    final syncState = ref.read(syncStatusProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解决冲突'),
        content: Text('发现 ${syncState.conflicts.length} 个文件冲突，请选择解决方式：'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 使用本地版本
              Navigator.pop(context);
            },
            child: const Text('使用本地版本'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 使用远程版本
              Navigator.pop(context);
            },
            child: const Text('使用远程版本'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 打开手动合并界面
            },
            child: const Text('手动合并'),
          ),
        ],
      ),
    );
  }

  void _showSyncIntervalDialog(BuildContext context) {
    final intervals = ['每 5 分钟', '每 15 分钟', '每 30 分钟', '每 1 小时', '每 6 小时', '每天'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择同步间隔'),
        children: intervals
            .map((interval) => SimpleDialogOption(
                  onPressed: () {
                    // TODO: 保存设置
                    Navigator.pop(context);
                  },
                  child: Text(interval),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _manualPush(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncStatusProvider.notifier);
    final plugins = notifier.availablePlugins;
    if (plugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置同步方式')),
      );
      return;
    }
    // TODO: 选择插件并推送
  }

  Future<void> _manualPull(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncStatusProvider.notifier);
    final plugins = notifier.availablePlugins;
    if (plugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置同步方式')),
      );
      return;
    }
    // TODO: 选择插件并拉取
  }

  Future<void> _manualSync(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(syncStatusProvider.notifier);
    final plugins = notifier.availablePlugins;
    if (plugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置同步方式')),
      );
      return;
    }
    // TODO: 选择插件并同步
  }
}
