import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/storage/storage_providers.dart';
import 'package:stargazer/core/theme/app_theme.dart';

/// 天气类型枚举
enum WeatherType {
  clear,    // 晴朗
  cloudy,   // 多云
  shaky,    // 摇曳
  foggy,    // 雾
  stormy,   // 暴风雨
  hazy,     // 雾霾
}

/// 天气配置（描述某种天气状态的视觉参数）
class WeatherConfig {
  final WeatherType type;
  final String name;
  final String emoji;
  final Color overlayColor;
  final double overlayOpacity;
  final double fogDensity;
  final double starBrightness;
  final double starShakeIntensity;

  const WeatherConfig({
    required this.type,
    required this.name,
    required this.emoji,
    required this.overlayColor,
    required this.overlayOpacity,
    required this.fogDensity,
    required this.starBrightness,
    required this.starShakeIntensity,
  });

  /// 从另一种天气配置线性插值
  WeatherConfig lerpTo(WeatherConfig other, double t) {
    return WeatherConfig(
      type: t < 0.5 ? type : other.type,
      name: t < 0.5 ? name : other.name,
      emoji: t < 0.5 ? emoji : other.emoji,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t)!,
      overlayOpacity: _lerpDouble(overlayOpacity, other.overlayOpacity, t),
      fogDensity: _lerpDouble(fogDensity, other.fogDensity, t),
      starBrightness: _lerpDouble(starBrightness, other.starBrightness, t),
      starShakeIntensity: _lerpDouble(starShakeIntensity, other.starShakeIntensity, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}

/// 天气配置表
const Map<WeatherType, WeatherConfig> _weatherConfigs = {
  WeatherType.clear: WeatherConfig(
    type: WeatherType.clear,
    name: '晴朗',
    emoji: '☀️',
    overlayColor: Color(0xFFFFA726),
    overlayOpacity: 0.0,
    fogDensity: 0.0,
    starBrightness: 1.0,
    starShakeIntensity: 0.0,
  ),
  WeatherType.cloudy: WeatherConfig(
    type: WeatherType.cloudy,
    name: '多云',
    emoji: '⛅',
    overlayColor: Color(0xFF90A4AE),
    overlayOpacity: 0.1,
    fogDensity: 0.05,
    starBrightness: 0.8,
    starShakeIntensity: 0.0,
  ),
  WeatherType.shaky: WeatherConfig(
    type: WeatherType.shaky,
    name: '摇曳',
    emoji: '🌬️',
    overlayColor: Color(0xFF80CBC4),
    overlayOpacity: 0.05,
    fogDensity: 0.0,
    starBrightness: 0.9,
    starShakeIntensity: 0.8,
  ),
  WeatherType.foggy: WeatherConfig(
    type: WeatherType.foggy,
    name: '雾',
    emoji: '🌫️',
    overlayColor: Color(0xFFB0BEC5),
    overlayOpacity: 0.2,
    fogDensity: 0.5,
    starBrightness: 0.6,
    starShakeIntensity: 0.0,
  ),
  WeatherType.stormy: WeatherConfig(
    type: WeatherType.stormy,
    name: '暴风雨',
    emoji: '⛈️',
    overlayColor: Color(0xFF311B92),
    overlayOpacity: 0.35,
    fogDensity: 0.15,
    starBrightness: 0.3,
    starShakeIntensity: 2.5,
  ),
  WeatherType.hazy: WeatherConfig(
    type: WeatherType.hazy,
    name: '雾霾',
    emoji: '😶‍🌫️',
    overlayColor: Color(0xFF8D6E63),
    overlayOpacity: 0.25,
    fogDensity: 0.3,
    starBrightness: 0.5,
    starShakeIntensity: 0.2,
  ),
};

/// 心情天气系统（实例版 - 供 weather_effects.dart 使用）
/// 管理当前天气状态、平滑过渡和星星抖动
class MoodWeatherSystem {
  WeatherType _currentType;
  WeatherType _targetType;
  double _transitionProgress = 1.0; // 1.0 = 完全到达目标
  final Random _random = Random();
  double _shakeOffsetX = 0.0;
  double _shakeOffsetY = 0.0;
  double _shakeTime = 0.0;

  MoodWeatherSystem({WeatherType initialType = WeatherType.clear})
      : _currentType = initialType,
        _targetType = initialType;

  WeatherType get currentType => _currentType;
  WeatherType get targetType => _targetType;

  /// 设置目标天气（当心情变化时调用）
  void setTargetWeather(WeatherType newType) {
    if (newType == _targetType) return;
    _currentType = _getInterpolatedType();
    _targetType = newType;
    _transitionProgress = 0.0;
  }

  /// 根据心情分数设置天气
  void setWeatherFromMoodScore(double score) {
    final type = _moodScoreToWeatherType(score);
    setTargetWeather(type);
  }

  /// 根据心情字符串设置天气
  void setWeatherFromMoodString(String? mood) {
    final type = _moodStringToWeatherType(mood);
    setTargetWeather(type);
  }

  /// 获取插值后的天气配置（平滑过渡）
  WeatherConfig getInterpolatedWeather() {
    final from = _weatherConfigs[_currentType]!;
    final to = _weatherConfigs[_targetType]!;
    if (_transitionProgress >= 1.0) return to;
    return from.lerpTo(to, _transitionProgress);
  }

  /// 每帧调用，更新过渡动画和抖动
  void update(double dt) {
    // 过渡动画
    if (_transitionProgress < 1.0) {
      _transitionProgress = (_transitionProgress + dt * 0.5).clamp(0.0, 1.0);
      if (_transitionProgress >= 1.0) {
        _currentType = _targetType;
      }
    }

    // 星星抖动
    final config = getInterpolatedWeather();
    if (config.starShakeIntensity > 0) {
      _shakeTime += dt;
      _shakeOffsetX = sin(_shakeTime * 3.7) * config.starShakeIntensity
          + sin(_shakeTime * 7.3) * config.starShakeIntensity * 0.3;
      _shakeOffsetY = cos(_shakeTime * 4.1) * config.starShakeIntensity
          + cos(_shakeTime * 6.9) * config.starShakeIntensity * 0.3;
    } else {
      _shakeOffsetX = 0;
      _shakeOffsetY = 0;
    }
  }

  /// 获取星星抖动偏移量
  Offset getStarShakeOffset() {
    return Offset(_shakeOffsetX, _shakeOffsetY);
  }

  WeatherType _getInterpolatedType() {
    return _transitionProgress < 0.5 ? _currentType : _targetType;
  }

  static WeatherType _moodScoreToWeatherType(double score) {
    if (score >= 4.5) return WeatherType.clear;
    if (score >= 3.5) return WeatherType.cloudy;
    if (score >= 2.5) return WeatherType.shaky;
    if (score >= 1.5) return WeatherType.foggy;
    if (score >= 0.5) return WeatherType.stormy;
    return WeatherType.hazy;
  }

  static WeatherType _moodStringToWeatherType(String? mood) {
    switch (mood) {
      case '😊':
        return WeatherType.clear;
      case '😎':
        return WeatherType.cloudy;
      case '🌬️':
        return WeatherType.shaky;
      case '😢':
        return WeatherType.foggy;
      case '😡':
        return WeatherType.stormy;
      case '😶‍🌫️':
        return WeatherType.hazy;
      default:
        return WeatherType.clear;
    }
  }

  // ========== 静态工具方法（供统计页面等使用） ==========

  /// 获取天气的中文名称
  static String getWeatherName(WeatherType type) => _weatherConfigs[type]!.name;

  /// 获取天气的图标 emoji
  static String getWeatherEmoji(WeatherType type) => _weatherConfigs[type]!.emoji;

  /// 获取天气的 IconData
  static IconData getWeatherIcon(WeatherType type) {
    switch (type) {
      case WeatherType.clear: return Icons.wb_sunny;
      case WeatherType.cloudy: return Icons.cloud;
      case WeatherType.shaky: return Icons.air;
      case WeatherType.foggy: return Icons.blur_on;
      case WeatherType.stormy: return Icons.flash_on;
      case WeatherType.hazy: return Icons.cloud;
    }
  }

  /// 获取天气的代表颜色
  static Color getWeatherColor(WeatherType type) => _weatherConfigs[type]!.overlayColor;
}

/// 心情天气统计页面
class MoodWeatherStatsPage extends ConsumerStatefulWidget {
  const MoodWeatherStatsPage({super.key});

  @override
  ConsumerState<MoodWeatherStatsPage> createState() => _MoodWeatherStatsPageState();
}

class _MoodWeatherStatsPageState extends ConsumerState<MoodWeatherStatsPage> {
  Map<WeatherType, int> _weatherStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final entryRepo = ref.read(entryRepositoryProvider);
    final entries = await entryRepo.getAllEntries();

    final stats = <WeatherType, int>{};
    for (final entry in entries) {
      final type = MoodWeatherSystem._moodStringToWeatherType(entry.mood);
      stats[type] = (stats[type] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _weatherStats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('心情天气'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weatherStats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('还没有天气数据', style: TextStyle(color: Colors.white54)),
                      SizedBox(height: 8),
                      Text(
                        '写日记时选择心情，系统会自动生成天气统计',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildWeatherList(theme),
    );
  }

  Widget _buildWeatherList(StarfieldTheme theme) {
    const allTypes = WeatherType.values;
    final total = _weatherStats.values.fold(0, (sum, count) => sum + count);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: allTypes.map((type) {
        final count = _weatherStats[type] ?? 0;
        final percentage = total > 0 ? (count / total * 100) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  MoodWeatherSystem.getWeatherIcon(type),
                  color: MoodWeatherSystem.getWeatherColor(type),
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MoodWeatherSystem.getWeatherName(type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count 天 (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MoodWeatherSystem.getWeatherColor(type),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
