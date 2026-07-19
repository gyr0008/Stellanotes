import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/security_repository.dart';
import 'biometric_auth.dart';

/// 应用锁拦截层
///
/// 在应用启动时显示，验证通过后才显示主界面。
class AppLock extends ConsumerStatefulWidget {
  final Widget child;

  const AppLock({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLock> createState() => _AppLockState();
}

class _AppLockState extends ConsumerState<AppLock> {
  final _pinController = TextEditingController();
  bool _isUnlocked = false;
  bool _isLoading = true;
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final repo = SecurityRepository();
    final lockEnabled = await repo.isLockEnabled();
    final biometricEnabled = await repo.isBiometricEnabled();

    if (!lockEnabled) {
      // 没有启用锁，直接显示主界面
      setState(() {
        _isUnlocked = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _lockEnabled = lockEnabled;
      _biometricEnabled = biometricEnabled;
      _isLoading = false;
    });

    // 如果启用了生物识别，自动尝试
    if (biometricEnabled) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final success = await BiometricAuth.authenticate();
    if (success && mounted) {
      setState(() => _isUnlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isUnlocked) {
      return widget.child;
    }

    // 显示锁屏界面
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1A3E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.white70,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Stargazer',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '输入密码解锁',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // PIN 输入
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 32),

                // 验证按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _verifyPin,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '解锁',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 生物识别按钮
                if (_biometricEnabled)
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint, size: 24),
                    label: const Text('使用生物识别'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;

    if (pin.length != 6) {
      setState(() => _error = '请输入 6 位密码');
      return;
    }

    final repo = SecurityRepository();
    final valid = await repo.verifyPin(pin);

    if (valid) {
      setState(() {
        _isUnlocked = true;
        _error = null;
      });
    } else {
      setState(() => _error = '密码错误');
      _pinController.clear();
    }
  }
}
