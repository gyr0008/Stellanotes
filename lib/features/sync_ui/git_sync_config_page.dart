import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_plugin.dart';
import '../../core/sync/git_sync_plugin.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/git_repo_manager.dart';
import '../providers/sync_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import '../../core/theme/theme_provider.dart';

/// Git / GitHub 同步配置页面
class GitSyncConfigPage extends ConsumerStatefulWidget {
  const GitSyncConfigPage({super.key});

  @override
  ConsumerState<GitSyncConfigPage> createState() => _GitSyncConfigPageState();
}

class _GitSyncConfigPageState extends ConsumerState<GitSyncConfigPage> {
  final _remoteUrlController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  String _selectedPlatform = 'GitHub';
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  static const List<String> _platforms = ['GitHub', 'Gitee', 'GitLab', '其他 Git 远程'];

  @override
  void dispose() {
    _remoteUrlController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Git 同步配置'),
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
          // ─── 平台选择 ───────────────────────────────
          const Text(
            '选择平台',
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
            children: _platforms.map((platform) {
              final isSelected = _selectedPlatform == platform;
              return ChoiceChip(
                label: Text(platform),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPlatform = platform);
                    _updatePlaceholder();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── 连接方式 ───────────────────────────────
          const Text(
            '连接方式',
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
                  leading: const Icon(Icons.key, color: Colors.white70),
                  title: const Text('Personal Access Token'),
                  subtitle: const Text('推荐，更安全'),
                  trailing: const Icon(Icons.radio_button_checked, color: Colors.white54),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.password, color: Colors.white70),
                  title: const Text('用户名 + 密码'),
                  subtitle: const Text('部分平台不支持'),
                  trailing: const Icon(Icons.radio_button_off, color: Colors.white38),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.white70),
                  title: const Text('OAuth 授权登录'),
                  subtitle: Text('$_selectedPlatform 账号授权'),
                  trailing: const Icon(Icons.radio_button_off, color: Colors.white38),
                  onTap: () => _startOAuth(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 仓库配置 ───────────────────────────────
          const Text(
            '仓库配置',
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
                  controller: _remoteUrlController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '远程仓库 URL',
                    hintText: _getPlaceholder(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _branchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '分支名称',
                    hintText: 'main',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Token 输入 ────────────────────────────
          FrostedCard(
            effect: theme.glassEffect,
            child: TextField(
              obscureText: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Access Token',
                hintText: '输入你的 Personal Access Token',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showTokenHelp(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Token 仅存储在本地，不会上传到任何服务器',
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

          // ─── 帮助信息 ──────────────────────────────
          if (_selectedPlatform == 'GitHub') ...[
            const Text(
              '如何获取 GitHub Token',
              style: TextStyle(
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
                  children: [
                    _buildHelpStep('1', '打开 GitHub → Settings → Developer settings'),
                    const SizedBox(height: 8),
                    _buildHelpStep('2', '点击 Personal access tokens → Tokens (classic)'),
                    const SizedBox(height: 8),
                    _buildHelpStep('3', '点击 Generate new token'),
                    const SizedBox(height: 8),
                    _buildHelpStep('4', '勾选 repo 权限，生成并复制 Token'),
                    const SizedBox(height: 8),
                    _buildHelpStep('5', '粘贴到上方输入框'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  String _getPlaceholder() {
    switch (_selectedPlatform) {
      case 'GitHub':
        return 'https://github.com/用户名/仓库名.git';
      case 'Gitee':
        return 'https://gitee.com/用户名/仓库名.git';
      case 'GitLab':
        return 'https://gitlab.com/用户名/仓库名.git';
      default:
        return 'https://example.com/用户名/仓库名.git';
    }
  }

  void _updatePlaceholder() {
    // placeholder 通过 _getPlaceholder() 动态获取
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final url = _remoteUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isConnecting = false;
        _errorMessage = '请输入远程仓库 URL';
      });
      return;
    }

    try {
      final gitManager = ref.read(gitRepoManagerProvider);
      final plugin = GitSyncPlugin(gitManager);

      final result = await plugin.connect({
        'remoteUrl': url,
        'remoteName': 'origin',
        'branch': _branchController.text.trim().isEmpty
            ? 'main'
            : _branchController.text.trim(),
      });

      if (result.success) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        // 注册插件
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
    // TODO: 断开连接逻辑
  }

  void _startOAuth(BuildContext context) {
    // TODO: 实现 OAuth 流程
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$_selectedPlatform OAuth 登录'),
        content: const Text('OAuth 授权登录功能开发中，请先使用 Personal Access Token 方式连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showTokenHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 Access Token'),
        content: const Text(
          'Access Token 是访问 Git 远程仓库的凭证。'
          '它比密码更安全，可以设置权限范围和过期时间。\n\n'
          'Token 仅存储在本地设备的加密存储中，不会上传到任何服务器。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
