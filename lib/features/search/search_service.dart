import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_providers.dart';
import 'package:stargazer/core/storage/entry_repository.dart';
import 'package:stargazer/core/storage/todo_repository.dart';

/// 搜索结果类型
enum SearchResultType {
  entry,
  todo,
  tag,
}

/// 搜索结果项
class SearchResultItem {
  final SearchResultType type;
  final int id;
  final String title;
  final String snippet;
  final DateTime? date;
  final String? mood;
  final bool? done;
  final int? priority;
  final List<String> matchedTags;

  SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    required this.snippet,
    this.date,
    this.mood,
    this.done,
    this.priority,
    this.matchedTags = const [],
  });
}

/// 搜索服务
class SearchService {
  final EntryRepository _entryRepo;
  final TodoRepository _todoRepo;

  SearchService(this._entryRepo, this._todoRepo);

  /// 全文搜索（支持日记和待办）
  Future<List<SearchResultItem>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResultItem>[];
    final lowerQuery = query.toLowerCase();

    // 搜索日记
    final entries = await _searchEntries(lowerQuery);
    results.addAll(entries);

    // 搜索待办
    final todos = await _searchTodos(lowerQuery);
    results.addAll(todos);

    // 搜索标签
    final tags = await _searchTags(lowerQuery);
    results.addAll(tags);

    return results;
  }

  /// 搜索日记条目
  Future<List<SearchResultItem>> _searchEntries(String query) async {
    final entries = await _entryRepo.searchEntries(query);
    final allTags = await _entryRepo.getAllTags();

    return entries.map((entry) {
      // 提取匹配片段
      final snippet = _extractSnippet(entry.content, query);
      final title = entry.title.isEmpty ? _extractTitle(entry.content) : entry.title;

      return SearchResultItem(
        type: SearchResultType.entry,
        id: entry.id,
        title: title,
        snippet: snippet,
        date: entry.createdAt,
        mood: entry.mood,
      );
    }).toList();
  }

  /// 搜索待办事项
  Future<List<SearchResultItem>> _searchTodos(String query) async {
    final allTodos = await _todoRepo.getAllTodos();
    final filtered = allTodos.where((todo) {
      return todo.title.toLowerCase().contains(query);
    }).toList();

    return filtered.map((todo) {
      return SearchResultItem(
        type: SearchResultType.todo,
        id: todo.id,
        title: todo.title,
        snippet: todo.title,
        date: todo.createdAt,
        done: todo.done,
        priority: todo.priority,
      );
    }).toList();
  }

  /// 搜索标签
  Future<List<SearchResultItem>> _searchTags(String query) async {
    final allTags = await _entryRepo.getAllTags();
    final filtered = allTags.where((tag) {
      return tag.name.toLowerCase().contains(query);
    }).toList();

    return filtered.map((tag) {
      return SearchResultItem(
        type: SearchResultType.tag,
        id: tag.id,
        title: '#${tag.name}',
        snippet: '标签',
      );
    }).toList();
  }

  /// 从内容中提取匹配片段
  String _extractSnippet(String content, String query) {
    final lowerContent = content.toLowerCase();
    final index = lowerContent.indexOf(query);

    if (index == -1) {
      // 没有直接匹配，返回前100个字符
      return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }

    // 提取匹配位置前后的文本
    final start = (index - 30).clamp(0, content.length);
    final end = (index + query.length + 70).clamp(0, content.length);

    var snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }

  /// 从内容中提取标题（第一行）
  String _extractTitle(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // 去掉 Markdown 标题符号
        if (trimmed.startsWith('#')) {
          return trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        }
        return trimmed.length > 50 ? '${trimmed.substring(0, 50)}...' : trimmed;
      }
    }
    return '无标题';
  }

  /// 高级搜索：带筛选条件
  Future<List<SearchResultItem>> advancedSearch({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    String? mood,
    String? tagName,
    bool? todoDone,
  }) async {
    var results = await search(query);

    // 日期筛选
    if (startDate != null || endDate != null) {
      results = results.where((item) {
        if (item.date == null) return false;
        if (startDate != null && item.date!.isBefore(startDate)) return false;
        if (endDate != null && item.date!.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    // 情绪筛选
    if (mood != null) {
      results = results.where((item) => item.mood == mood).toList();
    }

    // 待办完成状态筛选
    if (todoDone != null) {
      results = results.where((item) => item.done == todoDone).toList();
    }

    return results;
  }

  /// 获取搜索建议（热门搜索词）
  Future<List<String>> getSearchSuggestions(String prefix) async {
    if (prefix.isEmpty) return [];

    final suggestions = <String>{};

    // 从日记标题中提取
    final entries = await _entryRepo.getAllEntries();
    for (final entry in entries) {
      final title = entry.title.isEmpty ? _extractTitle(entry.content) : entry.title;
      if (title.toLowerCase().contains(prefix.toLowerCase())) {
        suggestions.add(title);
      }
    }

    // 从标签中提取
    final tags = await _entryRepo.getAllTags();
    for (final tag in tags) {
      if (tag.name.toLowerCase().contains(prefix.toLowerCase())) {
        suggestions.add('#${tag.name}');
      }
    }

    return suggestions.take(10).toList();
  }
}

// ─── Providers ─────────────────────────────────────────

final searchServiceProvider = Provider<SearchService>((ref) {
  final entryRepo = ref.watch(entryRepositoryProvider);
  final todoRepo = ref.watch(todoRepositoryProvider);
  return SearchService(entryRepo, todoRepo);
});

/// 搜索状态
class SearchState {
  final String query;
  final List<SearchResultItem> results;
  final bool isSearching;
  final List<String> suggestions;
  final List<String> searchHistory;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.suggestions = const [],
    this.searchHistory = const [],
  });

  SearchState copyWith({
    String? query,
    List<SearchResultItem>? results,
    bool? isSearching,
    List<String>? suggestions,
    List<String>? searchHistory,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      suggestions: suggestions ?? this.suggestions,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

/// 搜索状态管理
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;

  SearchNotifier(this._searchService) : super(SearchState());

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isSearching: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false, suggestions: []);
      return;
    }

    // 获取搜索建议
    final suggestions = await _searchService.getSearchSuggestions(query);
    state = state.copyWith(suggestions: suggestions);

    // 执行搜索
    final results = await _searchService.search(query);
    state = state.copyWith(results: results, isSearching: false);

    // 添加到搜索历史
    _addToHistory(query);
  }

  Future<void> advancedSearch({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    String? mood,
    String? tagName,
    bool? todoDone,
  }) async {
    state = state.copyWith(query: query, isSearching: true);

    final results = await _searchService.advancedSearch(
      query: query,
      startDate: startDate,
      endDate: endDate,
      mood: mood,
      tagName: tagName,
      todoDone: todoDone,
    );

    state = state.copyWith(results: results, isSearching: false);

    if (query.isNotEmpty) {
      _addToHistory(query);
    }
  }

  void _addToHistory(String query) {
    final history = List<String>.from(state.searchHistory);
    history.remove(query);
    history.insert(0, query);
    if (history.length > 20) history.removeLast();
    state = state.copyWith(searchHistory: history);
  }

  void clearHistory() {
    state = state.copyWith(searchHistory: []);
  }

  void clearSearch() {
    state = SearchState(searchHistory: state.searchHistory);
  }
}

final searchStateProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});
