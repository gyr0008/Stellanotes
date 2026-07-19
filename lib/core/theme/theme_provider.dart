import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_theme.dart';

// ─── 主题 Provider ──────────────────────────────────────
final appThemeProvider = StateNotifierProvider<AppThemeNotifier, StarfieldTheme>(
  (ref) => AppThemeNotifier(),
);

class AppThemeNotifier extends StateNotifier<StarfieldTheme> {
  AppThemeNotifier() : super(PresetThemes.deepSpace) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeJson = prefs.getString('starfield_theme');
    if (themeJson != null) {
      try {
        state = StarfieldTheme.fromJson(
          jsonDecode(themeJson) as Map<String, dynamic>,
        );
      } catch (_) {
        // 解析失败则使用默认主题
      }
    }
  }

  Future<void> setTheme(StarfieldTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('starfield_theme', jsonEncode(theme.toJson()));
  }

  Future<void> resetToPreset(StarfieldTheme preset) async {
    await setTheme(preset);
  }

  Future<void> updateDiaryColor(Color color) async {
    await setTheme(state.copyWith(
      diaryColor: state.diaryColor.copyWith(color: color),
    ));
  }

  Future<void> updateTodoColor(Color color) async {
    await setTheme(state.copyWith(
      todoColor: state.todoColor.copyWith(color: color),
    ));
  }

  Future<void> updateTagColor(Color color) async {
    await setTheme(state.copyWith(
      tagColor: state.tagColor.copyWith(color: color),
    ));
  }

  Future<void> updateBackground(Color top, Color bottom) async {
    await setTheme(state.copyWith(
      backgroundTop: top,
      backgroundBottom: bottom,
    ));
  }

  Future<void> updateGlassEffect(GlassEffect effect) async {
    await setTheme(state.copyWith(glassEffect: effect));
  }

  /// 根据主题生成 Material ThemeData
  ThemeData toMaterialTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: state.backgroundTop,
      colorScheme: ColorScheme.dark(
        primary: state.diaryColor.color,
        secondary: state.todoColor.color,
        surface: state.backgroundBottom,
        onSurface: Colors.white.withOpacity(0.9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Colors.white.withOpacity(0.8)),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(state.glassEffect.opacity),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
