import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/image_repository.dart';
import '../../shared/widgets/frosted_card.dart';
import 'backup_service.dart';

/// 数据备份页面
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupPath;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 备份说明
          FrostedCard(
            effect: theme.glassEffect,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.diaryColor.color),
                    const SizedBox(width: 12),
                    const Text(
                      '备份说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 备份包含所有日记、待办和图片\n'
                  '• 支持加密保护（可选）\n'
                  '• 恢复时会合并到现有数据\n'
                  '• 建议定期备份到安全位置',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 创建备份
          const Text(
            '创建备份',
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
            onTap: _isBackingUp ? null : _createBackup,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.diaryColor.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.backup,
                    color: theme.diaryColor.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '立即备份',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _isBackingUp ? '备份中...' : '点击创建备份文件',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isBackingUp)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 恢复备份
          const Text(
            '恢复备份',
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
            onTap: _isRestoring ? null : _restoreBackup,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.todoColor.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restore,
                    color: theme.todoColor.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '从文件恢复',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _isRestoring ? '恢复中...' : '选择备份文件恢复数据',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isRestoring)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 上次备份
          if (_lastBackupPath != null)
            FrostedCard(
              effect: theme.glassEffect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text(
                        '上次备份',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lastBackupPath!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final entryRepo = ref.read(entryRepositoryProvider);
      final todoRepo = ref.read(todoRepositoryProvider);
      final imageRepo = ImageRepository();

      final backupService = BackupService(
        entryRepo: entryRepo,
        todoRepo: todoRepo,
        imageRepo: imageRepo,
      );

      final backupFile = await backupService.createBackup();

      setState(() => _lastBackupPath = backupFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份成功: ${backupFile.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'enc'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.first.path!);

    setState(() => _isRestoring = true);

    try {
      final entryRepo = ref.read(entryRepositoryProvider);
      final todoRepo = ref.read(todoRepositoryProvider);
      final imageRepo = ImageRepository();

      final backupService = BackupService(
        entryRepo: entryRepo,
        todoRepo: todoRepo,
        imageRepo: imageRepo,
      );

      await backupService.restoreBackup(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('恢复成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }
}
