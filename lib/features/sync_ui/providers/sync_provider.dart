import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stargazer/core/sync/sync_plugin.dart';

/// 同步状态 Provider
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>(
  (ref) => SyncStatusNotifier(ref),
);

class SyncStatusState {
  final SyncState state;
  final String? currentPlugin;
  final DateTime? lastSyncedAt;
  final String? message;
  final List<SyncConflict> conflicts;

  const SyncStatusState({
    this.state = SyncState.idle,
    this.currentPlugin,
    this.lastSyncedAt,
    this.message,
    this.conflicts = const [],
  });

  SyncStatusState copyWith({
    SyncState? state,
    String? currentPlugin,
    DateTime? lastSyncedAt,
    String? message,
    List<SyncConflict>? conflicts,
  }) {
    return SyncStatusState(
      state: state ?? this.state,
      currentPlugin: currentPlugin ?? this.currentPlugin,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  final Ref ref;
  final List<SyncPlugin> _plugins = [];

  SyncStatusNotifier(this.ref) : super(const SyncStatusState());

  void registerPlugin(SyncPlugin plugin) {
    _plugins.add(plugin);
  }

  List<SyncPlugin> get availablePlugins => List.unmodifiable(_plugins);

  Future<SyncResult> syncWithPlugin(String pluginId) async {
    final plugin = _plugins.firstWhere(
      (p) => p.pluginId == pluginId,
      orElse: () => throw Exception('插件未找到: $pluginId'),
    );

    state = state.copyWith(
      state: SyncState.syncing,
      currentPlugin: pluginId,
      message: '正在同步...',
    );

    try {
      final result = await plugin.sync();

      state = state.copyWith(
        state: result.success ? SyncState.synced : SyncState.error,
        lastSyncedAt: result.success ? DateTime.now() : null,
        message: result.message,
        conflicts: result.conflicts,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        state: SyncState.error,
        message: '同步失败: $e',
      );
      return SyncResult.error(e.toString());
    }
  }

  Future<void> resolveConflict(
      String pluginId, ConflictResolution resolution) async {
    final plugin = _plugins.firstWhere((p) => p.pluginId == pluginId);
    final result = await plugin.resolveConflict(resolution);

    if (result.success) {
      state = state.copyWith(
        state: SyncState.synced,
        conflicts: [],
        message: '冲突已解决',
      );
    } else {
      state = state.copyWith(message: '冲突解决失败: ${result.message}');
    }
  }

  void reset() {
    state = const SyncStatusState();
  }
}
