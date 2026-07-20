import 'package:local_auth/local_auth.dart';

/// 生物识别认证封装
class BiometricAuth {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  static Future<bool> isSupported() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// 获取可用的生物识别类型
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// 执行生物识别认证
  static Future<bool> authenticate({
    String reason = '验证身份以解锁 Stargazer',
    String title = '生物识别认证',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
