import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/webdav_sync_plugin.dart';
import 'providers/sync_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../core/theme/theme_provider.dart';

/// WebDAV 同步配置页面
class WebDAVSyncConfigPage extends ConsumerStatefulWidget {
  const WebDAVSyncConfigPage({super.key});

  @override
  ConsumerState<WebDAVSyncConfigPage> createState() =>
      _WebDAVSyncConfigPageState();
}

class _WebDAVSyncConfigPageState extends ConsumerState<WebDAVSyncConfigPage> {
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController(text: '/stargazer');
  String _selectedService = 'Nextcloud';
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  static const List<String> _services = [
    'Nextcloud',
    'ownCloud',
    '群晖 NAS',
    '威联通 NAS',
    'AList',
    '其他 WebDAV',
  ];

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 同步配置'),
        actions: [
          if (_isConnected)
            TextButton(
              onPressed: _disconnect,
              child: const Text('断开'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 服务类型 ───────────────────────────────
          const Text(
            '服务类型',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              final isSelected = _selectedService == service;
              return ChoiceChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedService = service);
                    _applyServicePreset();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── 服务器配置 ────────────────────────────
          const Text(
            '服务器配置',
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
              children: [
                TextField(
                  controller: _baseUrlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '服务器地址',
                    hintText: _getBaseUrlHint(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.link, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remotePathController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '远程路径',
                    hintText: '/stargazer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.folder, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 认证信息 ──────────────────────────────
          const Text(
            '认证信息',
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
              children: [
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '用户名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.lock, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '认证信息仅存储在本地，不会上传到任何服务器',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
          ),

          const SizedBox(height: 24),

          // ─── 错误信息 ──────────────────────────────
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ─── 连接按钮 ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isConnecting ? null : _connect,
              style: FilledButton.styleFrom(
                backgroundColor: theme.diaryColor.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isConnected ? '重新连接' : '连接'),
            ),
          ),

          const SizedBox(height: 24),

          // ─── 各平台帮助 ────────────────────────────
          _buildServiceHelp(),
        ],
      ),
    );
  }

  String _getBaseUrlHint() {
    switch (_selectedService) {
      case 'Nextcloud':
        return 'https://your-nextcloud.com/remote.php/dav';
      case 'ownCloud':
        return 'https://your-owncloud.com/remote.php/webdav';
      case '群晖 NAS':
        return 'http://192.168.1.100:5005';
      case '威联通 NAS':
        return 'http://192.168.1.100:8080';
      case 'AList':
        return 'http://192.168.1.100:5244/dav';
      default:
        return 'https://your-webdav-server.com/dav';
    }
  }

  void _applyServicePreset() {
    // 根据选择的服务类型自动填充常用路径
    switch (_selectedService) {
      case 'Nextcloud':
        if (_remotePathController.text.isEmpty) {
          _remotePathController.text = '/stargazer';
        }
        break;
      case '群晖 NAS':
      case '威联通 NAS':
        if (_remotePathController.text.isEmpty) {
          _remotePathController.text = '/stargazer';
        }
        break;
    }
  }

  Widget _buildServiceHelp() {
    String title;
    List<String> steps;

    switch (_selectedService) {
      case 'Nextcloud':
        title = 'Nextcloud 配置指南';
        steps = [
          '确保 Nextcloud 已启用 WebDAV 功能',
          '服务器地址格式：https://域名/remote.php/dav',
          '用户名和密码与 Nextcloud 登录账号相同',
          '远程路径为 Nextcloud 中的文件夹路径',
        ];
        break;
      case '群晖 NAS':
        title = '群晖 NAS 配置指南';
        steps = [
          '在群晖中安装 WebDAV Server 套件',
          '在控制面板中启用 WebDAV 服务',
          '默认端口：HTTP 5005 / HTTPS 5006',
          '使用群晖账号登录',
        ];
        break;
      case '威联通 NAS':
        title = '威联通 NAS 配置指南';
        steps = [
          '在 App Center 中安装 WebDAV 应用',
          '默认端口：8080 (HTTP) / 8081 (HTTPS)',
          '使用 NAS 管理账号登录',
        ];
        break;
      case 'AList':
        title = 'AList 配置指南';
        steps = [
          '确保 AList 已启用 WebDAV 功能',
          '默认端口：5244',
          '服务器地址：http://IP:5244/dav',
          '使用 AList 管理账号登录',
        ];
        break;
      default:
        title = '其他 WebDAV 服务';
        steps = [
          '确保服务器支持标准 WebDAV 协议',
          '填写正确的服务器地址和端口',
          '输入有效的用户名和密码',
          '远程路径以 / 开头',
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text(step, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final baseUrl = _baseUrlController.text.trim();
    if (baseUrl.isEmpty) {
      setState(() {
        _isConnecting = false;
        _errorMessage = '请输入服务器地址';
      });
      return;
    }

    try {
      final plugin = WebDAVSyncPlugin();

      final result = await plugin.connect({
        'baseUrl': baseUrl,
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'remotePath': _remotePathController.text.trim().isEmpty
            ? '/stargazer'
            : _remotePathController.text.trim(),
      });

      if (result.success) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        ref.read(syncStatusProvider.notifier).registerPlugin(plugin);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = '连接失败: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isConnected = false;
    });
  }
}
