import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import 'search_service.dart';

/// 搜索页面
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showFilters = false;

  // 筛选条件
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMood;
  bool? _todoDone;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.read(searchStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '搜索日记、待办、标签...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (_showFilters) {
              searchNotifier.advancedSearch(
                query: value,
                startDate: _startDate,
                endDate: _endDate,
                mood: _selectedMood,
                todoDone: _todoDone,
              );
            } else {
              searchNotifier.search(value);
            }
          },
          onSubmitted: (value) {
            searchNotifier.search(value);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: _showFilters ? theme.diaryColor.color : Colors.white70,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选面板
          if (_showFilters) _buildFilterPanel(theme, searchNotifier),

          // 搜索建议
          if (searchState.suggestions.isNotEmpty && !_showFilters)
            _buildSuggestions(searchState.suggestions, searchNotifier),

          // 搜索结果
          Expanded(
            child: searchState.isSearching
                ? const Center(child: CircularProgressIndicator())
                : searchState.results.isEmpty
                    ? _buildEmptyState(searchState)
                    : _buildResults(searchState.results, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(
    StarfieldTheme theme,
    SearchNotifier searchNotifier,
  ) {
    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '筛选条件',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 日期范围
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  '开始日期',
                  _startDate,
                  () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  '结束日期',
                  _endDate,
                  () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 情绪筛选
          Wrap(
            spacing: 8,
            children: [
              _buildMoodChip('😊', '5'),
              _buildMoodChip('😎', '4'),
              _buildMoodChip('😐', '3'),
              _buildMoodChip('😢', '2'),
              _buildMoodChip('😡', '1'),
            ],
          ),
          const SizedBox(height: 12),

          // 待办状态
          Row(
            children: [
              ChoiceChip(
                label: const Text('未完成'),
                selected: _todoDone == false,
                onSelected: (selected) {
                  setState(() {
                    _todoDone = selected ? false : null;
                    _applyFilters(searchNotifier);
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已完成'),
                selected: _todoDone == true,
                onSelected: (selected) {
                  setState(() {
                    _todoDone = selected ? true : null;
                    _applyFilters(searchNotifier);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date.month}/${date.day}'
                  : label,
              style: TextStyle(
                color: date != null ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(String emoji, String value) {
    return ChoiceChip(
      label: Text(emoji),
      selected: _selectedMood == value,
      onSelected: (selected) {
        setState(() {
          _selectedMood = selected ? value : null;
          _applyFilters(ref.read(searchStateProvider.notifier));
        });
      },
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
        _applyFilters(ref.read(searchStateProvider.notifier));
      });
    }
  }

  void _applyFilters(SearchNotifier searchNotifier) {
    searchNotifier.advancedSearch(
      query: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
      mood: _selectedMood,
      todoDone: _todoDone,
    );
  }

  Widget _buildSuggestions(List<String> suggestions, SearchNotifier notifier) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 18, color: Colors.white54),
            title: Text(
              suggestion,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            onTap: () {
              _searchController.text = suggestion;
              notifier.search(suggestion);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(SearchState state) {
    if (state.query.isEmpty) {
      // 显示搜索历史
      if (state.searchHistory.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                '搜索日记、待办、标签',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(searchStateProvider.notifier).clearHistory();
                },
                child: const Text('清除', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          ...state.searchHistory.map((history) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 18, color: Colors.white54),
              title: Text(history, style: const TextStyle(color: Colors.white70)),
              onTap: () {
                _searchController.text = history;
                ref.read(searchStateProvider.notifier).search(history);
              },
            );
          }),
        ],
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            '没有找到匹配的结果',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<SearchResultItem> results, StarfieldTheme theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultItem(item, theme);
      },
    );
  }

  Widget _buildResultItem(SearchResultItem item, StarfieldTheme theme) {
    return FrostedCard(
      effect: theme.glassEffect,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _navigateToResult(item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor(item.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(item.type),
              color: _getTypeColor(item.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.snippet,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.date != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(item.date!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 待办状态
          if (item.type == SearchResultType.todo && item.done != null)
            Icon(
              item.done! ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.done! ? Colors.green : Colors.white38,
              size: 20,
            ),

          // 情绪
          if (item.mood != null)
            Text(
              _getMoodEmoji(item.mood!),
              style: const TextStyle(fontSize: 20),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.entry:
        return Colors.blue;
      case SearchResultType.todo:
        return Colors.green;
      case SearchResultType.tag:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.entry:
        return Icons.menu_book;
      case SearchResultType.todo:
        return Icons.check_box;
      case SearchResultType.tag:
        return Icons.tag;
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case '5':
        return '😊';
      case '4':
        return '😎';
      case '3':
        return '😐';
      case '2':
        return '😢';
      case '1':
        return '😡';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.year}/${date.month}/${date.day}';
  }

  void _navigateToResult(SearchResultItem item) {
    // TODO: 根据类型导航到对应页面
    switch (item.type) {
      case SearchResultType.entry:
        // Navigator.push(context, MaterialPageRoute(builder: (_) => JournalDetailPage(entryId: item.id)));
        break;
      case SearchResultType.todo:
        // 导航到待办页面并高亮该待办
        break;
      case SearchResultType.tag:
        // 导航到标签相关的日记列表
        break;
    }
  }
}
