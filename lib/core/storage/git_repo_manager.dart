import 'dart:io';
import 'package:path/path.dart' as p;

/// 本地 Git 仓库管理器
///
/// 管理 vault 目录的 Git 仓库，自动 commit 变更。
/// 依赖系统已安装 git 命令行工具。
class GitRepoManager {
  final String repoPath;
  bool _initialized = false;

  GitRepoManager(this.repoPath);

  bool get isInitialized => _initialized;

  /// 初始化或打开 Git 仓库
  Future<void> init() async {
    final repoDir = Directory(repoPath);
    if (!await repoDir.exists()) {
      await repoDir.create(recursive: true);
    }

    final gitDir = Directory(p.join(repoPath, '.git'));
    if (!await gitDir.exists()) {
      await _runGit('init');
      await _runGit('config user.name "Stargazer"');
      await _runGit('config user.email "stargazer@local"');
    }

    _initialized = true;
  }

  /// Stage 所有变更并提交
  Future<bool> commitAll(String message) async {
    if (!_initialized) await init();

    try {
      await _runGit('add -A');
      // 检查是否有变更
      final status = await _runGit('status --porcelain');
      if (status.trim().isEmpty) return false; // 没有变更

      await _runGit('commit -m "$message"');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 自动提交（带时间戳）
  Future<bool> autoCommit() {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return commitAll('auto: $timestamp');
  }

  /// 添加远程仓库
  Future<void> addRemote(String name, String url) async {
    await _runGit('remote add $name $url');
  }

  /// 移除远程仓库
  Future<void> removeRemote(String name) async {
    await _runGit('remote remove $name');
  }

  /// 获取远程仓库列表
  Future<List<String>> getRemotes() async {
    final result = await _runGit('remote -v');
    final lines = result.split('\n');
    final names = <String>{};
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) names.add(parts[0]);
      }
    }
    return names.toList();
  }

  /// Push 到远程
  Future<String> push(String remote, String branch) async {
    return await _runGit('push $remote $branch');
  }

  /// Pull 从远程
  Future<String> pull(String remote, String branch) async {
    return await _runGit('pull $remote $branch');
  }

  /// 获取当前分支
  Future<String> getCurrentBranch() async {
    return (await _runGit('rev-parse --abbrev-ref HEAD')).trim();
  }

  /// 获取最近 commit 日志
  Future<String> getRecentCommits({int count = 10}) async {
    return await _runGit('log --oneline -$count');
  }

  /// 检查工作区状态
  Future<String> getStatus() async {
    return await _runGit('status');
  }

  /// 检查是否有未提交的变更
  Future<bool> hasUncommittedChanges() async {
    final status = await _runGit('status --porcelain');
    return status.trim().isNotEmpty;
  }

  /// 执行原始 git 命令（供同步插件使用）
  Future<String> runGitRaw(String args) async {
    final result = await Process.run('git', args.split(' '),
        workingDirectory: repoPath);
    if (result.exitCode != 0) {
      throw Exception('Git error: ${result.stderr}');
    }
    return result.stdout.toString();
  }

  Future<String> _runGit(String args) => runGitRaw(args);
}
