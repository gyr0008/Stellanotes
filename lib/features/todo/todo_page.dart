import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/todo_repository.dart';
import 'providers/todo_manager_provider.dart';
import '../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/storage/database.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
          ),
          if (state.completedTodos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => _confirmClearCompleted(context, ref),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.filteredTodos.isEmpty
              ? _buildEmptyState(context, state.filter)
              : _buildTodoList(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    String message;
    switch (filter) {
      case 'active':
        message = '没有活跃的待办';
        break;
      case 'completed':
        message = '还没有完成的待办';
        break;
      case 'today':
        message = '今天还没有待办';
        break;
      default:
        message = '还没有待办事项';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outline_blank, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加待办',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(BuildContext context, WidgetRef ref, TodoManagerState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = state.filteredTodos[index];
        return _buildTodoCard(context, ref, todo);
      },
    );
  }

  Widget _buildTodoCard(BuildContext context, WidgetRef ref, Todo todo) {
    final priorityColors = {
      0: Colors.red,
      1: Colors.orange,
      2: Colors.blue,
      3: Colors.grey,
    };

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 完成按钮
          GestureDetector(
            onTap: () => ref.read(todoManagerProvider.notifier).toggleTodo(todo.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: todo.done ? Colors.green : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: todo.done ? Colors.green : Colors.transparent,
              ),
              child: todo.done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // 优先级标记
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColors[todo.priority]?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'P${todo.priority}',
              style: TextStyle(
                color: priorityColors[todo.priority],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: todo.done ? TextDecoration.lineThrough : null,
                    color: todo.done ? Colors.white.withOpacity(0.5) : Colors.white,
                  ),
                ),
                if (todo.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '完成于 ${todo.completedAt!.month}/${todo.completedAt!.day}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => ref.read(todoManagerProvider.notifier).deleteTodo(todo.id),
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int priority = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加待办'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '待办标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('优先级:'),
                  const SizedBox(width: 16),
                  ...[0, 1, 2, 3].map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('P$p'),
                      selected: priority == p,
                      onSelected: (selected) => setState(() => priority = p),
                    ),
                  )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(todoManagerProvider.notifier).addTodo(
                        controller.text.trim(),
                        priority: priority,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '筛选待办',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[
              ('全部', 'all'),
              ('活跃', 'active'),
              ('已完成', 'completed'),
              ('今天', 'today'),
            ].map((item) => ListTile(
              title: Text(item.$1),
              onTap: () {
                ref.read(todoManagerProvider.notifier).setFilter(item.$2);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _confirmClearCompleted(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除已完成'),
        content: const Text('确定要删除所有已完成的待办吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoManagerProvider.notifier).clearCompleted();
              Navigator.pop(context);
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
