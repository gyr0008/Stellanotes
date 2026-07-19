/// 同步插件抽象接口
///
/// 所有同步方式（Git、WebDAV、REST API）都实现此接口。
/// 用户可在设置中选择并配置多个同步目标。
abstract class SyncPlugin {
  /// 插件唯一标识
  String get pluginId;

  /// 插件显示名称
  String get displayName;

  /// 是否已连接
  bool get isConnected;

  /// 连接/授权
  Future<SyncResult> connect(Map<String, String> config);

  /// 断开连接
  Future<void> disconnect();

  /// 推送本地变更到远程
  Future<SyncResult> push();

  /// 从远程拉取变更
  Future<SyncResult> pull();

  /// 双向同步（pull → merge → push）
  Future<SyncResult> sync();

  /// 获取同步状态
  Future<SyncStatus> status();

  /// 解决冲突
  Future<SyncResult> resolveConflict(ConflictResolution resolution);
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final List<SyncConflict>? conflicts;
  final int filesChanged;

  const SyncResult({
    required this.success,
    required this.message,
    this.conflicts,
    this.filesChanged = 0,
  });

  factory SyncResult.ok({String message = '同步成功', int filesChanged = 0}) {
    return SyncResult(
      success: true,
      message: message,
      filesChanged: filesChanged,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(success: false, message: message);
  }
}

/// 同步状态
enum SyncState {
  idle,       // 空闲
  syncing,    // 同步中
  synced,     // 已同步
  conflict,   // 有冲突
  error,      // 错误
  offline,    // 离线
}

class SyncStatus {
  final SyncState state;
  final DateTime? lastSyncedAt;
  final String? remoteName;
  final int pendingChanges;

  const SyncStatus({
    required this.state,
    this.lastSyncedAt,
    this.remoteName,
    this.pendingChanges = 0,
  });
}

/// 同步冲突
class SyncConflict {
  final String filePath;
  final String localContent;
  final String remoteContent;
  final String? baseContent; // 三方合并的基准

  const SyncConflict({
    required this.filePath,
    required this.localContent,
    required this.remoteContent,
    this.baseContent,
  });
}

/// 冲突解决策略
enum ConflictResolution {
  useLocal,    // 使用本地版本
  useRemote,   // 使用远程版本
  manual,      // 手动合并
}
