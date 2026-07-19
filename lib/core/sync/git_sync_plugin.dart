import 'dart:io';
import 'package:path/path.dart' as p;
import '../sync_plugin.dart';
import '../storage/git_repo_manager.dart';

/// Git 同步插件
///
/// 支持 GitHub / Gitee / GitLab / 任意 Git 远程仓库。
/// 通过 GitRepoManager 操作本地仓库，push/pull 到远程。
class GitSyncPlugin implements SyncPlugin {
  @override
  String get pluginId => 'git';

  @override
  String get displayName => 'Git 同步';

  final GitRepoManager _gitManager;
  String? _remoteName;
  String? _remoteUrl;
  String _branch = 'main';
  bool _connected = false;

  GitSyncPlugin(this._gitManager);

  @override
  bool get isConnected => _connected;

  @override
  Future<SyncResult> connect(Map<String, String> config) async {
    try {
      _remoteUrl = config['remoteUrl'];
      _remoteName = config['remoteName'] ?? 'origin';
      _branch = config['branch'] ?? 'main';

      if (_remoteUrl == null) {
        return SyncResult.error('请提供远程仓库 URL');
      }

      // 初始化本地仓库
      await _gitManager.init();

      // 添加远程（如果已存在则先移除）
      final remotes = await _gitManager.getRemotes();
      if (remotes.contains(_remoteName)) {
        await _gitManager.removeRemote(_remoteName!);
      }
      await _gitManager.addRemote(_remoteName!, _remoteUrl!);

      // 尝试拉取远程内容
      try {
        await _gitManager.pull(_remoteName!, _branch);
      } catch (_) {
        // 远程为空仓库，首次 push 即可
      }

      _connected = true;
      return SyncResult.ok(message: '已连接到 $_remoteUrl');
    } catch (e) {
      return SyncResult.error('连接失败: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    if (_remoteName != null) {
      try {
        await _gitManager.removeRemote(_remoteName!);
      } catch (_) {}
    }
    _connected = false;
    _remoteName = null;
    _remoteUrl = null;
  }

  @override
  Future<SyncResult> push() async {
    if (!_connected) return SyncResult.error('未连接远程仓库');

    try {
      // 先提交本地变更
      await _gitManager.autoCommit();

      await _gitManager.push(_remoteName!, _branch);
      return SyncResult.ok(message: '推送成功');
    } catch (e) {
      return SyncResult.error('推送失败: $e');
    }
  }

  @override
  Future<SyncResult> pull() async {
    if (!_connected) return SyncResult.error('未连接远程仓库');

    try {
      await _gitManager.pull(_remoteName!, _branch);
      return SyncResult.ok(message: '拉取成功');
    } catch (e) {
      // 检查是否是冲突
      final errorStr = e.toString();
      if (errorStr.contains('conflict') || errorStr.contains('merge')) {
        return SyncResult.error('存在合并冲突，请手动解决');
      }
      return SyncResult.error('拉取失败: $e');
    }
  }

  @override
  Future<SyncResult> sync() async {
    if (!_connected) return SyncResult.error('未连接远程仓库');

    try {
      // 1. 提交本地变更
      await _gitManager.autoCommit();

      // 2. 拉取远程
      await _gitManager.pull(_remoteName!, _branch);

      // 3. 如果有冲突，返回冲突信息
      final hasChanges = await _gitManager.hasUncommittedChanges();
      if (hasChanges) {
        return SyncResult(
          success: false,
          message: '存在冲突，需要手动合并',
          conflicts: [
            SyncConflict(
              filePath: 'working-directory',
              localContent: '',
              remoteContent: '',
            ),
          ],
        );
      }

      // 4. 推送
      await _gitManager.push(_remoteName!, _branch);

      return SyncResult.ok(message: '同步完成');
    } catch (e) {
      return SyncResult.error('同步失败: $e');
    }
  }

  @override
  Future<SyncStatus> status() async {
    if (!_connected) {
      return const SyncStatus(state: SyncState.offline);
    }

    try {
      final hasChanges = await _gitManager.hasUncommittedChanges();
      final recentLog = await _gitManager.getRecentCommits(count: 1);

      return SyncStatus(
        state: hasChanges ? SyncState.syncing : SyncState.synced,
        lastSyncedAt: DateTime.now(),
        remoteName: _remoteName,
        pendingChanges: hasChanges ? 1 : 0,
      );
    } catch (_) {
      return const SyncStatus(state: SyncState.error);
    }
  }

  @override
  Future<SyncResult> resolveConflict(ConflictResolution resolution) async {
    try {
      switch (resolution) {
        case ConflictResolution.useLocal:
          await _gitManager.runGitRaw('checkout --theirs .');
          await _gitManager.runGitRaw('add -A');
          await _gitManager.runGitRaw('commit -m "resolve: use local"');
          break;
        case ConflictResolution.useRemote:
          await _gitManager.runGitRaw('checkout --ours .');
          await _gitManager.runGitRaw('add -A');
          await _gitManager.runGitRaw('commit -m "resolve: use remote"');
          break;
        case ConflictResolution.manual:
          return SyncResult.error('手动合并请在终端中完成');
      }

      await _gitManager.push(_remoteName!, _branch);
      return SyncResult.ok(message: '冲突已解决并推送');
    } catch (e) {
      return SyncResult.error('解决冲突失败: $e');
    }
  }

  /// 配置信息
  Map<String, String> get config => {
        'remoteUrl': _remoteUrl ?? '',
        'remoteName': _remoteName ?? '',
        'branch': _branch,
      };
}
