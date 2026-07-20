import 'dart:math';
import 'package:flutter/material.dart';

/// 声音场景类型
enum SoundscapeType {
  deepSpace,      // 深空漫游
  rainyNight,     // 雨夜书房
  forestMorning,  // 森林清晨
  campfire,       // 篝火夜晚
  underwater,     // 海底世界
  custom,         // 自定义混合
}

/// 单个声音轨道
class SoundTrack {
  final String name;
  final String assetPath;
  final IconData icon;
  double volume;
  bool enabled;

  SoundTrack({
    required this.name,
    required this.assetPath,
    required this.icon,
    this.volume = 0.7,
    this.enabled = false,
  });
}

/// 声音场景配置
class SoundscapeScene {
  final String name;
  final String description;
  final SoundscapeType type;
  final IconData icon;
  final Color color;
  final List<SoundTrack> tracks;

  const SoundscapeScene({
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.tracks,
  });

  /// 预设场景
  static final deepSpace = SoundscapeScene(
    name: '深空漫游',
    description: '低频嗡鸣 + 偶尔的信号声',
    type: SoundscapeType.deepSpace,
    icon: Icons.rocket_launch,
    color: Color(0xFF1A237E),
    tracks: [
      SoundTrack(
        name: '宇宙嗡鸣',
        assetPath: 'assets/sounds/deep_space_drone.ogg',
        icon: Icons.graphic_eq,
        volume: 0.6,
      ),
      SoundTrack(
        name: '信号脉冲',
        assetPath: 'assets/sounds/signal_pulse.ogg',
        icon: Icons.wifi,
        volume: 0.3,
      ),
      SoundTrack(
        name: '星风',
        assetPath: 'assets/sounds/stellar_wind.ogg',
        icon: Icons.air,
        volume: 0.4,
      ),
    ],
  );

  static final rainyNight = SoundscapeScene(
    name: '雨夜书房',
    description: '雨声 + 翻书声 + 远处雷声',
    type: SoundscapeType.rainyNight,
    icon: Icons.nights_stay,
    color: Color(0xFF37474F),
    tracks: [
      SoundTrack(
        name: '雨声',
        assetPath: 'assets/sounds/rain.ogg',
        icon: Icons.water_drop,
        volume: 0.8,
      ),
      SoundTrack(
        name: '雷声',
        assetPath: 'assets/sounds/thunder.ogg',
        icon: Icons.flash_on,
        volume: 0.3,
      ),
      SoundTrack(
        name: '翻书声',
        assetPath: 'assets/sounds/pages.ogg',
        icon: Icons.menu_book,
        volume: 0.2,
      ),
    ],
  );

  static final forestMorning = SoundscapeScene(
    name: '森林清晨',
    description: '鸟鸣 + 溪流 + 风声',
    type: SoundscapeType.forestMorning,
    icon: Icons.park,
    color: Color(0xFF2E7D32),
    tracks: [
      SoundTrack(
        name: '鸟鸣',
        assetPath: 'assets/sounds/birds.ogg',
        icon: Icons.flutter_dash,
        volume: 0.6,
      ),
      SoundTrack(
        name: '溪流',
        assetPath: 'assets/sounds/stream.ogg',
        icon: Icons.water,
        volume: 0.5,
      ),
      SoundTrack(
        name: '风声',
        assetPath: 'assets/sounds/wind.ogg',
        icon: Icons.air,
        volume: 0.4,
      ),
    ],
  );

  static final campfire = SoundscapeScene(
    name: '篝火夜晚',
    description: '柴火噼啪 + 虫鸣',
    type: SoundscapeType.campfire,
    icon: Icons.local_fire_department,
    color: Color(0xFFBF360C),
    tracks: [
      SoundTrack(
        name: '柴火',
        assetPath: 'assets/sounds/campfire.ogg',
        icon: Icons.local_fire_department,
        volume: 0.7,
      ),
      SoundTrack(
        name: '虫鸣',
        assetPath: 'assets/sounds/crickets.ogg',
        icon: Icons.bug_report,
        volume: 0.4,
      ),
      SoundTrack(
        name: '夜风',
        assetPath: 'assets/sounds/night_wind.ogg',
        icon: Icons.air,
        volume: 0.3,
      ),
    ],
  );

  static final underwater = SoundscapeScene(
    name: '海底世界',
    description: '水泡声 + 鲸鱼叫声',
    type: SoundscapeType.underwater,
    icon: Icons.waves,
    color: Color(0xFF01579B),
    tracks: [
      SoundTrack(
        name: '水泡',
        assetPath: 'assets/sounds/bubbles.ogg',
        icon: Icons.bubble_chart,
        volume: 0.5,
      ),
      SoundTrack(
        name: '鲸鱼',
        assetPath: 'assets/sounds/whale.ogg',
        icon: Icons.set_meal,
        volume: 0.3,
      ),
      SoundTrack(
        name: '海流',
        assetPath: 'assets/sounds/ocean_current.ogg',
        icon: Icons.waves,
        volume: 0.6,
      ),
    ],
  );

  /// 所有预设场景
  static final List<SoundscapeScene> allScenes = [
    deepSpace,
    rainyNight,
    forestMorning,
    campfire,
    underwater,
  ];
}

/// 声音景观引擎
class SoundscapeEngine {
  SoundscapeScene? _currentScene;
  bool _isPlaying = false;
  double _masterVolume = 0.8;
  int? _timerMinutes;

  /// 当前场景
  SoundscapeScene? get currentScene => _currentScene;

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  /// 主音量
  double get masterVolume => _masterVolume;

  /// 定时关闭时间（分钟）
  int? get timerMinutes => _timerMinutes;

  /// 播放场景
  void playScene(SoundscapeScene scene) {
    _currentScene = scene;
    _isPlaying = true;

    // 启用所有轨道
    for (final track in scene.tracks) {
      track.enabled = true;
    }

    // TODO: 实际音频播放逻辑
    // 使用 just_audio 或 audioplayers 播放
  }

  /// 暂停
  void pause() {
    _isPlaying = false;
    // TODO: 暂停音频
  }

  /// 恢复
  void resume() {
    _isPlaying = true;
    // TODO: 恢复音频
  }

  /// 停止
  void stop() {
    _isPlaying = false;
    _currentScene = null;
    // TODO: 停止所有音频
  }

  /// 设置主音量
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    // TODO: 更新所有播放器音量
  }

  /// 设置单个轨道音量
  void setTrackVolume(SoundTrack track, double volume) {
    track.volume = volume.clamp(0.0, 1.0);
    // TODO: 更新该轨道播放器音量
  }

  /// 切换轨道启用状态
  void toggleTrack(SoundTrack track) {
    track.enabled = !track.enabled;
    // TODO: 启用/禁用该轨道播放器
  }

  /// 设置定时关闭
  void setTimer(int? minutes) {
    _timerMinutes = minutes;
    // TODO: 实现定时关闭逻辑
  }

  /// 获取场景与天气的联动建议
  SoundscapeScene? getSuggestedScene(String? mood) {
    final score = _moodToScore(mood);

    if (score >= 4.5) return SoundscapeScene.forestMorning;
    if (score >= 3.5) return SoundscapeScene.campfire;
    if (score >= 2.5) return SoundscapeScene.rainyNight;
    return SoundscapeScene.deepSpace;
  }

  double _moodToScore(String? mood) {
    switch (mood) {
      case '😊':
        return 5.0;
      case '😎':
        return 4.0;
      case '😐':
        return 3.0;
      case '😢':
        return 2.0;
      case '😡':
        return 1.0;
      default:
        return 3.0;
    }
  }
}
