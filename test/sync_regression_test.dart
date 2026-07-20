import 'package:flutter_test/flutter_test.dart';
import 'package:stargazer/core/storage/git_repo_manager.dart';
import 'package:stargazer/core/sync/git_sync_plugin.dart';
import 'package:stargazer/core/sync/sync_plugin.dart';
import 'package:stargazer/core/sync/webdav_sync_plugin.dart';

/// D1 回归用的 GitRepoManager 替身：记录所有 git 命令，不真正执行。
/// 用于锁定"冲突解决方向"这一曾反转的缺陷。
class _FakeGitRepoManager extends GitRepoManager {
  _FakeGitRepoManager(super.repoPath);

  final List<String> commands = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<String>> getRemotes() async => [];

  @override
  Future<void> removeRemote(String name) async {}

  @override
  Future<void> addRemote(String name, String url) async {}

  @override
  Future<String> pull(String remote, String branch) async => '';

  @override
  Future<String> push(String remote, String branch) async => '';

  @override
  Future<String> runGitRaw(String args) async {
    commands.add(args);
    return '';
  }
}

void main() {
  // ──────────────────────────────────────────────────────
  // D1：Git 冲突解决方向回归
  // 历史缺陷：useLocal 误用 --theirs、useRemote 误用 --ours，
  // 导致"保留本地"实际丢弃本地、"保留远程"实际丢弃远程（数据丢失）。
  // 修复后必须：useLocal → --ours，useRemote → --theirs。
  // ──────────────────────────────────────────────────────
  group('D1 Git 冲突解决方向回归', () {
    late _FakeGitRepoManager mgr;
    late GitSyncPlugin plugin;

    setUp(() {
      mgr = _FakeGitRepoManager('/tmp/fake-vault');
      plugin = GitSyncPlugin(mgr);
    });

    Future<SyncResult> _connect() => plugin.connect({
          'remoteUrl': 'https://example.com/repo.git',
          'remoteName': 'origin',
          'branch': 'main',
        });

    test('connect 成功并置为已连接', () async {
      final result = await _connect();
      expect(result.success, isTrue);
    });

    test('useLocal 必须保留本地版本（--ours）', () async {
      await _connect();
      await plugin.resolveConflict(ConflictResolution.useLocal);
      expect(mgr.commands, contains('checkout --ours .'),
          reason: 'D1 回归失败：保留本地应使用 --ours');
      expect(mgr.commands, isNot(contains('checkout --theirs .')),
          reason: 'D1 回归失败：保留本地绝不能误用 --theirs（会导致本地修改丢失）');
    });

    test('useRemote 必须保留远程版本（--theirs）', () async {
      await _connect();
      await plugin.resolveConflict(ConflictResolution.useRemote);
      expect(mgr.commands, contains('checkout --theirs .'),
          reason: 'D1 回归失败：保留远程应使用 --theirs');
      expect(mgr.commands, isNot(contains('checkout --ours .')),
          reason: 'D1 回归失败：保留远程绝不能误用 --ours（会导致远程修改丢失）');
    });
  });

  // ──────────────────────────────────────────────────────
  // D2：WebDAV 同步"假成功"回归
  // 历史缺陷：push/pull/sync/resolveConflict 均为 TODO 桩却返回成功，
  // 用户误以为数据已备份。修复后这些操作必须如实返回错误，绝不 success。
  // ──────────────────────────────────────────────────────
  group('D2 WebDAV 同步假成功回归', () {
    late WebDAVSyncPlugin plugin;

    setUp(() => plugin = WebDAVSyncPlugin());

    test('所有同步操作均不谎报成功', () async {
      final results = await Future.wait([
        plugin.push(),
        plugin.pull(),
        plugin.sync(),
        plugin.resolveConflict(ConflictResolution.useLocal),
      ]);
      for (final r in results) {
        expect(r.success, isFalse,
            reason: 'D2 回归失败：未实现的同步绝不能返回 success');
      }
    });

    test('status 绝不谎报为已同步（未实现即非成功态）', () async {
      final status = await plugin.status();
      // D2 回归：未实现的 WebDAV 同步无论是否已连接，都绝不能谎报为"已同步/成功"。
      // 真实状态可能是 offline（尚未连接）或 error（已连接但未实现），二者皆非成功，均符合要求。
      expect(status.state, isNot(SyncState.synced),
          reason: 'D2 回归失败：未实现的同步绝不能谎报为已同步');
    });

    test('推送返回"尚未实现"提示而非"成功"', () async {
      final push = await plugin.push();
      expect(push.message, contains('尚未实现'));
    });
  });
}
