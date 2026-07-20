import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/storage/storage_providers.dart';
import '../../shared/widgets/frosted_card.dart';
import 'package:stargazer/core/theme/theme_provider.dart';

/// 日历视图页面
///
/// 用日历展示每天的日记和待办，直观回顾。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final entryRepo = ref.read(entryRepositoryProvider);
    final todoRepo = ref.read(todoRepositoryProvider);

    final entries = await entryRepo.getAllEntries();
    final todos = await todoRepo.getAllTodos();

    final events = <DateTime, List<CalendarEvent>>{};

    // 添加日记事件
    for (final entry in entries) {
      final date = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      events.putIfAbsent(date, () => []);
      events[date]!.add(CalendarEvent(
        type: CalendarEventType.entry,
        title: entry.title.isEmpty ? '无标题' : entry.title,
        mood: entry.mood,
        time: entry.createdAt,
      ));
    }

    // 添加待办事件
    for (final todo in todos) {
      final date = DateTime(todo.createdAt.year, todo.createdAt.month, todo.createdAt.day);
      events.putIfAbsent(date, () => []);
      events[date]!.add(CalendarEvent(
        type: CalendarEventType.todo,
        title: todo.title,
        done: todo.done,
        time: todo.createdAt,
      ));
    }

    setState(() => _events = events);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
      ),
      body: Column(
        children: [
          // 日历组件
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.diaryColor.color.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.diaryColor.color,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.todoColor.color,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
          ),
          const SizedBox(height: 16),

          // 选中日期的事件列表
          Expanded(
            child: _selectedDay != null
                ? _buildEventList(_selectedDay!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(DateTime day) {
    final events = _getEventsForDay(day);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '这一天没有记录',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return FrostedCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: event.type == CalendarEventType.entry
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event.type == CalendarEventType.entry
                      ? Icons.menu_book
                      : Icons.check_box,
                  color: event.type == CalendarEventType.entry
                      ? Colors.blue
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (event.mood != null)
                      Text(
                        event.mood!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    Text(
                      '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        );
      },
    );
  }
}

/// 日历事件类型
enum CalendarEventType {
  entry,  // 日记
  todo,   // 待办
}

/// 日历事件数据
class CalendarEvent {
  final CalendarEventType type;
  final String title;
  final String? mood;
  final bool? done;
  final DateTime time;

  CalendarEvent({
    required this.type,
    required this.title,
    this.mood,
    this.done,
    required this.time,
  });
}
