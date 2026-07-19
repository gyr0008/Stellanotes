import 'dart:io';
import 'package:path/path.dart' as p;
import '../sync_plugin.dart';

/// WebDAV 同步插件
///
/// 支持标准 WebDAV 协议，适配：
/// - NAS（群晖/威联通）
/// - Nextcloud / ownCloud
/// - AList
/// - 任何标准 WebDAV 服务
class WebDAVSyncPlugin implements SyncPlugin {
  @override
  String get pluginId => 'webdav';

  @override
  String get displayName => 'WebDAV 同步';

  String? _baseUrl;
  String? _username;
  String? _password;
  String _remotePath = '/stargazer';
  bool _connected = false;
  HttpClient? _client;

  WebDAVSyncPlugin();

  @override
  bool get isConnected => _connected;

  @override
  Future<SyncResult> connect(Map<String, String> config) async {
    try {
      _baseUrl = config['baseUrl'];
      _username = config['username'];
      _password = config['password'];
      _remotePath = config['remotePath'] ?? '/stargazer';

      if (_baseUrl == null) {
        return SyncResult.error('请提供 WebDAV 服务器地址');
      }

      _client = HttpClient();

      // 测试连接
      final testResult = await _testConnection();
      if (!testResult) {
        return SyncResult.error('无法连接到 WebDAV 服务器');
      }

      // 创建远程目录
      await _createRemoteDir(_remotePath);

      _connected = true;
      return SyncResult.ok(message: '已连接到 $_baseUrl（同步功能开发中，暂未实现）');
    } catch (e) {
      return SyncResult.error('连接失败: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _client?.close();
    _client = null;
    _connected = false;
  }

  @override
  Future<SyncResult> push() async {
    // WebDAV 文件同步尚未实现：禁止谎报成功，避免用户误以为数据已备份。
    // 同步能力未就绪前，无论是否已连接都如实返回错误，绝不声称成功。
    return SyncResult.error('WebDAV 推送尚未实现，本地数据未被上传');
  }

  @override
  Future<SyncResult> pull() async {
    // WebDAV 文件同步尚未实现：禁止谎报成功
    return SyncResult.error('WebDAV 拉取尚未实现，未获取到远程数据');
  }

  @override
  Future<SyncResult> sync() async {
    // 先 pull 再 push（二者均未实现，会如实返回错误，绝不谎报成功）
    final pullResult = await pull();
    if (!pullResult.success) return pullResult;

    final pushResult = await push();
    if (!pushResult.success) return pushResult;

    return SyncResult.ok(message: '同步完成');
  }

  @override
  Future<SyncStatus> status() async {
    if (!_connected) {
      return const SyncStatus(state: SyncState.offline);
    }

    // WebDAV 同步未实现，如实反映为错误状态，避免伪装成"已就绪"
    return const SyncStatus(state: SyncState.error);
  }

  @override
  Future<SyncResult> resolveConflict(ConflictResolution resolution) async {
    // 按修改时间覆盖的冲突策略尚未实现，禁止谎报已解决
    return SyncResult.error('WebDAV 冲突解决尚未实现');
  }

  // ─── 内部方法 ───────────────────────────────────────

  Future<bool> _testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl$_remotePath');
      final request = await _client!.openUrl('PROPFIND', uri);
      request.headers.set('Depth', '0');

      if (_username != null && _password != null) {
        final credentials = '$_username:$_password';
        final base64 = base64Encode(credentials.codeUnits);
        request.headers.set('Authorization', 'Basic $base64');
      }

      final response = await request.close();
      return response.statusCode == 207 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createRemoteDir(String path) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final request = await _client!.openUrl('MKCOL', uri);

      if (_username != null && _password != null) {
        final credentials = '$_username:$_password';
        final base64 = base64Encode(credentials.codeUnits);
        request.headers.set('Authorization', 'Basic $base64');
      }

      await request.close();
    } catch (_) {
      // 目录可能已存在
    }
  }

  String base64Encode(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b1 = bytes[i];
      final b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      result.writeCharCode(chars.codeUnitAt((b1 >> 2) & 0x3F));
      result.writeCharCode(chars.codeUnitAt(((b1 & 0x03) << 4) | ((b2 >> 4) & 0x0F)));

      if (i + 1 < bytes.length) {
        result.writeCharCode(chars.codeUnitAt(((b2 & 0x0F) << 2) | ((b3 >> 6) & 0x03)));
      } else {
        result.write('=');
      }

      if (i + 2 < bytes.length) {
        result.writeCharCode(chars.codeUnitAt(b3 & 0x3F));
      } else {
        result.write('=');
      }
    }
    return result.toString();
  }
}
