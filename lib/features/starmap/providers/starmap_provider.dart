import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stargazer/core/storage/storage_providers.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';
import 'package:stargazer/core/storage/markdown_vault.dart';
import 'package:stargazer/core/storage/git_repo_manager.dart';
import 'package:stargazer/core/theme/app_theme.dart';
import 'package:stargazer/features/starmap/providers/force_layout.dart';
import 'package:stargazer/core/theme/theme_provider.dart';

/// 星空图谱数据 Provider
final starmapDataProvider = FutureProvider<StarmapData>((ref) async {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final todoRepo = ref.watch(todoRepositoryProvider);
  final theme = ref.watch(appThemeProvider);

  final entries = await entryRepo.getAllEntries();
  final todos = await todoRepo.getAllTodos();
  final tags = await entryRepo.getAllTags();

  // 构建图谱节点
  final nodes = <StarNode>[];
  final links = <StarLink>[];

  // 日记节点
  for (final entry in entries) {
    nodes.add(StarNode(
      id: entry.id,
      label: entry.title.isEmpty ? '无标题' : entry.title,
      type: 'diary',
      x: 0,
      y: 0,
      mass: 1.5, // 日记节点稍重
    ));
  }

  // 待办节点
  for (final todo in todos) {
    nodes.add(StarNode(
      id: 10000 + todo.id, // 用偏移避免 ID 冲突
      label: todo.title,
      type: todo.done ? 'done_todo' : 'todo',
      x: 0,
      y: 0,
      mass: 0.8,
    ));

    // 待办-日记关联
    final linkedEntries = await todoRepo.getEntriesForTodo(todo.id);
    for (final entry in linkedEntries) {
      links.add(StarLink(
        sourceId: entry.id,
        targetId: 10000 + todo.id,
        strength: 0.8,
      ));
    }
  }

  // 标签节点
  for (final tag in tags) {
    nodes.add(StarNode(
      id: 20000 + tag.id,
      label: '#${tag.name}',
      type: 'tag',
      x: 0,
      y: 0,
      mass: 1.2,
    ));

    // 标签-日记关联
    final taggedEntries = await entryRepo.getEntriesByTag(tag.name);
    for (final entry in taggedEntries) {
      links.add(StarLink(
        sourceId: entry.id,
        targetId: 20000 + tag.id,
        strength: 0.6,
      ));
    }
  }

  // 日记间关联
  for (final entry in entries) {
    final relations = await entryRepo.getRelationsForEntry(entry.id);
    for (final relation in relations) {
      links.add(StarLink(
        sourceId: relation.fromId,
        targetId: relation.toId,
        strength: 0.5,
      ));
    }
  }

  return StarmapData(
    nodes: nodes,
    links: links,
    theme: theme,
  );
});

class StarmapData {
  final List<StarNode> nodes;
  final List<StarLink> links;
  final StarfieldTheme theme;

  StarmapData({
    required this.nodes,
    required this.links,
    required this.theme,
  });
}

/// 图谱交互状态 Provider
final starmapInteractionProvider =
    StateNotifierProvider<StarmapInteractionNotifier, StarmapInteractionState>(
  (ref) => StarmapInteractionNotifier(),
);

class StarmapInteractionState {
  final int? selectedNodeId;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final Set<int> pinnedNodeIds;

  const StarmapInteractionState({
    this.selectedNodeId,
    this.zoom = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
    this.pinnedNodeIds = const {},
  });

  StarmapInteractionState copyWith({
    int? selectedNodeId,
    double? zoom,
    double? offsetX,
    double? offsetY,
    Set<int>? pinnedNodeIds,
  }) {
    return StarmapInteractionState(
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      zoom: zoom ?? this.zoom,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      pinnedNodeIds: pinnedNodeIds ?? this.pinnedNodeIds,
    );
  }
}

class StarmapInteractionNotifier
    extends StateNotifier<StarmapInteractionState> {
  StarmapInteractionNotifier() : super(const StarmapInteractionState());

  void selectNode(int? nodeId) {
    state = state.copyWith(selectedNodeId: nodeId);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.2, 5.0));
  }

  void setOffset(double x, double y) {
    state = state.copyWith(offsetX: x, offsetY: y);
  }

  void togglePinNode(int nodeId) {
    final pinned = Set<int>.from(state.pinnedNodeIds);
    if (pinned.contains(nodeId)) {
      pinned.remove(nodeId);
    } else {
      pinned.add(nodeId);
    }
    state = state.copyWith(pinnedNodeIds: pinned);
  }
}
