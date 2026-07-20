import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/entry_repository.dart';
import '../../core/storage/todo_repository.dart';

/// 通知栏快捷操作
///
/// 提供从通知栏快速创建日记/待办的功能。
class QuickActionNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 初始化通知插件
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// 通知点击回调
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: 根据 payload 导航到对应页面
    debugPrint('通知点击: ${response.payload}');
  }

  /// 显示每日提醒通知
  static Future<void> showDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '每日提醒',
      channelDescription: '每日日记提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      0,
      '写日记的时间到了',
      '今天还没有记录，来写点什么吧 ✨',
      _nextSchedule(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消每日提醒
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(0);
  }

  /// 显示待办提醒
  static Future<void> showTodoReminder({
    required int todoId,
    required String title,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'todo_reminder',
      '待办提醒',
      channelDescription: '待办事项提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      todoId,
      '待办提醒',
      title,
      details,
      payload: 'todo:$todoId',
    );
  }

  /// 显示待办完成通知
  static Future<void> showTodoCompleted(int count) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'todo_completed',
      '待办完成',
      channelDescription: '待办完成通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      9999,
      '今日待办',
      '今天已完成 $count 个待办事项 🎉',
      details,
    );
  }

  static TZDateTime _nextSchedule(int hour, int minute) {
    final now = TZDateTime.now(local);
    var scheduled = TZDateTime(local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
