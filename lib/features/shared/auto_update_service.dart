import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';

/// 版本信息
class VersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  final DateTime publishedAt;

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
    required this.publishedAt,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      downloadUrl: json['downloadUrl'] as String,
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }
}

/// 自动更新服务
class AutoUpdateService {
  // 更新检查 URL（需要部署实际的更新服务器）
  static const String _updateCheckUrl = 'https://api.stargazer.app/v1/update/check';
  
  PackageInfo? _packageInfo;

  /// 获取当前版本信息
  Future<PackageInfo> getCurrentVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  /// 检查更新
  Future<VersionInfo?> checkForUpdate() async {
    try {
      final currentInfo = await getCurrentVersion();
      final currentBuild = int.tryParse(currentInfo.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Current-Version': currentInfo.version,
          'X-Current-Build': currentBuild.toString(),
          'X-Platform': Platform.operatingSystem,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 检查是否有更新
        if (data['hasUpdate'] == true) {
          final updateInfo = VersionInfo.fromJson(data['update']);
          
          // 比较版本号
          if (updateInfo.buildNumber > currentBuild) {
            return updateInfo;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('检查更新失败: $e');
      return null;
    }
  }

  /// 下载并安装更新
  Future<bool> downloadAndInstall(
    VersionInfo versionInfo, {
    Function(double)? onProgress,
    Function(String)? onStatus,
  }) async {
    try {
      onStatus?.call('正在下载更新...');
      
      final response = await http.get(
        Uri.parse(versionInfo.downloadUrl),
        headers: {'Accept': 'application/octet-stream'},
      );

      if (response.statusCode != 200) {
        throw Exception('下载失败: ${response.statusCode}');
      }

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName = Platform.isAndroid 
          ? 'stargazer-${versionInfo.version}.apk'
          : 'stargazer-${versionInfo.version}.exe';
      final filePath = '${tempDir.path}/$fileName';

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      onStatus?.call('下载完成，准备安装...');

      // 安装
      if (Platform.isAndroid) {
        final result = await OpenFile.open(
          filePath,
          type: 'application/vnd.android.package-archive',
        );
        return result.type == ResultType.done;
      } else if (Platform.isWindows) {
        final result = await OpenFile.open(filePath);
        return result.type == ResultType.done;
      }

      return false;
    } catch (e) {
      print('下载安装失败: $e');
      onStatus?.call('安装失败: $e');
      return false;
    }
  }
}

/// 自动更新 Provider
final autoUpdateServiceProvider = Provider<AutoUpdateService>((ref) {
  return AutoUpdateService();
});

/// 自动更新设置页面
class AutoUpdateSettingsPage extends ConsumerStatefulWidget {
  const AutoUpdateSettingsPage({super.key});

  @override
  ConsumerState<AutoUpdateSettingsPage> createState() => _AutoUpdateSettingsPageState();
}

class _AutoUpdateSettingsPageState extends ConsumerState<AutoUpdateSettingsPage> {
  bool _autoCheck = true;
  String _currentVersion = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final service = ref.read(autoUpdateServiceProvider);
    final info = await service.getCurrentVersion();
    setState(() {
      _currentVersion = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _checkUpdate() async {
    setState(() => _isChecking = true);
    
    final service = ref.read(autoUpdateServiceProvider);
    final updateInfo = await service.checkForUpdate();
    
    setState(() => _isChecking = false);

    if (!mounted) return;

    if (updateInfo != null) {
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate,
        builder: (context) => _UpdateDialog(
          versionInfo: updateInfo,
          forceUpdate: updateInfo.forceUpdate,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前已是最新版本'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动更新'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前版本',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentVersion,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          FrostedCard(
            effect: theme.glassEffect,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('自动检查更新'),
                  subtitle: const Text('启动应用时自动检查新版本'),
                  value: _autoCheck,
                  activeColor: theme.diaryColor.color,
                  onChanged: (value) {
                    setState(() => _autoCheck = value);
                    // TODO: 保存到 SharedPreferences
                  },
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkUpdate,
              icon: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.update),
              label: Text(_isChecking ? '检查中...' : '检查更新'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.diaryColor.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 更新对话框
class _UpdateDialog extends ConsumerStatefulWidget {
  final VersionInfo versionInfo;
  final bool forceUpdate;

  const _UpdateDialog({
    required this.versionInfo,
    this.forceUpdate = false,
  });

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  double _downloadProgress = 0.0;
  String _status = '准备更新';
  bool _isDownloading = false;
  bool _isComplete = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedCard(
        effect: theme.glassEffect,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: theme.diaryColor.color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '发现新版本',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'v${widget.versionInfo.version}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (widget.versionInfo.changelog.isNotEmpty) ...[
              Text(
                '更新内容',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    widget.versionInfo.changelog,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.diaryColor.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ] else if (_isComplete) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '下载完成，准备安装',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.87),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  if (!widget.forceUpdate)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          '稍后',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    ),
                  if (!widget.forceUpdate) const SizedBox(width: 12),
                  Expanded(
                    flex: widget.forceUpdate ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _startUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.diaryColor.color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('立即更新'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _status = '正在下载更新...';
    });

    final service = AutoUpdateService();
    final success = await service.downloadAndInstall(
      widget.versionInfo,
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
      onStatus: (status) {
        setState(() {
          _status = status;
        });
      },
    );

    if (success) {
      setState(() {
        _isComplete = true;
      });
    } else {
      setState(() {
        _isDownloading = false;
        _status = '下载失败，请重试';
      });
    }
  }
}
