import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// 安全存储仓库
///
/// 管理 PIN 密码和生物识别设置。
/// 使用 flutter_secure_storage 加密存储（Android KeyStore / iOS Keychain）。
class SecurityRepository {
  static const _storage = FlutterSecureStorage();
  static const _keyPinHash = 'pin_hash';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyLockEnabled = 'lock_enabled';

  /// 是否已设置 PIN
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// 是否启用了应用锁
  Future<bool> isLockEnabled() async {
    final value = await _storage.read(key: _keyLockEnabled);
    return value == 'true';
  }

  /// 启用/禁用应用锁
  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _keyLockEnabled, value: enabled.toString());
  }

  /// 设置/更新 PIN
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _keyPinHash, value: hash);
    await _storage.write(key: _keyLockEnabled, value: 'true');
  }

  /// 验证 PIN 是否正确
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _keyPinHash);
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  /// 清除 PIN（关闭锁屏）
  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyLockEnabled);
    await _storage.delete(key: _keyBiometricEnabled);
  }

  /// 是否启用了生物识别
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// 设置生物识别开关
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// SHA-256 哈希 PIN
  String _hashPin(String pin) {
    final bytes = utf8.encode('stargazer_pin_$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
