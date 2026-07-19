import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/security_repository.dart';
import '../../shared/widgets/frosted_card.dart';
import 'biometric_auth.dart';

/// 安全设置页面
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = SecurityRepository();
    final lockEnabled = await repo.isLockEnabled();
    final biometricEnabled = await repo.isBiometricEnabled();
    final biometricSupported = await BiometricAuth.isSupported();
    final hasPin = await repo.hasPin();

    setState(() {
      _lockEnabled = lockEnabled;
      _biometricEnabled = biometricEnabled;
      _biometricSupported = biometricSupported;
      _hasPin = hasPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私与安全'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用锁开关
          FrostedCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: SwitchListTile(
              secondary: const Icon(Icons.lock, color: Colors.blue),
              title: const Text('应用锁'),
              subtitle: Text(
                _lockEnabled ? '已启用' : '未启用',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              value: _lockEnabled,
              onChanged: (value) async {
                if (value && !_hasPin) {
                  // 需要先设置密码
                  context.push('/settings/security/setup-pin');
                  return;
                }

                final repo = SecurityRepository();
                if (value) {
                  await repo.setPin(''); // 保持现有密码，只启用锁
                } else {
                  await repo.clearPin();
                }

                await _loadSettings();
              },
            ),
          ),

          // 设置/修改密码
          if (_hasPin)
            FrostedCard(
              margin: const EdgeInsets.only(bottom: 16),
              onTap: () => context.push('/settings/security/setup-pin'),
              child: const ListTile(
                leading: Icon(Icons.password, color: Colors.purple),
                title: Text('修改密码'),
                trailing: Icon(Icons.chevron_right, color: Colors.white38),
              ),
            ),

          // 生物识别
          if (_biometricSupported)
            FrostedCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: Colors.orange),
                title: const Text('生物识别'),
                subtitle: Text(
                  _biometricEnabled ? '已启用' : '未启用',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                value: _biometricEnabled,
                onChanged: _lockEnabled
                    ? (value) async {
                        final repo = SecurityRepository();
                        await repo.setBiometricEnabled(value);
                        await _loadSettings();
                      }
                    : null,
              ),
            ),

          // 说明
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70),
                    const SizedBox(width: 12),
                    const Text(
                      '说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 应用锁会在启动时要求输入密码\n'
                  '• 密码使用 SHA-256 加密存储\n'
                  '• 生物识别需要设备支持\n'
                  '• 忘记密码需要清除应用数据',
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
