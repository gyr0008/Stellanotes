import 'package:flutter/material.dart';

// ─── 星星颜色配置 ───────────────────────────────────────
class StarColor {
  final Color color;
  final double saturation;
  final double brightness;

  const StarColor({
    required this.color,
    this.saturation = 1.0,
    this.brightness = 1.0,
  });

  StarColor copyWith({Color? color, double? saturation, double? brightness}) {
    return StarColor(
      color: color ?? this.color,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
    );
  }

  Map<String, dynamic> toJson() => {
        'color': color.value.toRadixString(16),
        'saturation': saturation,
        'brightness': brightness,
      };

  factory StarColor.fromJson(Map<String, dynamic> json) {
    return StarColor(
      color: Color(int.parse(json['color'] as String, radix: 16)),
      saturation: json['saturation'] as double? ?? 1.0,
      brightness: json['brightness'] as double? ?? 1.0,
    );
  }
}

// ─── 毛玻璃效果配置 ─────────────────────────────────────
enum GlassPreset {
  none,      // 透明
  light,     // 轻雾
  frosted,   // 磨砂
  condensed, // 凝霜
  custom,    // 自定义
}

enum GlassBorder {
  none,
  thin,
  bright,
}

enum GlassShadow {
  none,
  light,
  heavy,
}

class GlassEffect {
  final GlassPreset preset;
  final double blurRadius;     // 0-40
  final double opacity;        // 0.1-0.9
  final Color? tint;           // 色调叠加
  final GlassBorder border;
  final GlassShadow shadow;

  const GlassEffect({
    this.preset = GlassPreset.frosted,
    this.blurRadius = 20,
    this.opacity = 0.35,
    this.tint,
    this.border = GlassBorder.thin,
    this.shadow = GlassShadow.light,
  });

  GlassEffect copyWith({
    GlassPreset? preset,
    double? blurRadius,
    double? opacity,
    Color? tint,
    GlassBorder? border,
    GlassShadow? shadow,
  }) {
    return GlassEffect(
      preset: preset ?? this.preset,
      blurRadius: blurRadius ?? this.blurRadius,
      opacity: opacity ?? this.opacity,
      tint: tint ?? this.tint,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.index,
        'blurRadius': blurRadius,
        'opacity': opacity,
        'tint': tint?.value.toRadixString(16),
        'border': border.index,
        'shadow': shadow.index,
      };

  factory GlassEffect.fromJson(Map<String, dynamic> json) {
    return GlassEffect(
      preset: GlassPreset.values[json['preset'] as int? ?? 2],
      blurRadius: json['blurRadius'] as double? ?? 20,
      opacity: json['opacity'] as double? ?? 0.35,
      tint: json['tint'] != null
          ? Color(int.parse(json['tint'] as String, radix: 16))
          : null,
      border: GlassBorder.values[json['border'] as int? ?? 1],
      shadow: GlassShadow.values[json['shadow'] as int? ?? 1],
    );
  }

  // 预设快捷构造
  static const none = GlassEffect(
    preset: GlassPreset.none,
    blurRadius: 0,
    opacity: 0.1,
    border: GlassBorder.none,
    shadow: GlassShadow.none,
  );

  static const light = GlassEffect(
    preset: GlassPreset.light,
    blurRadius: 8,
    opacity: 0.15,
    border: GlassBorder.thin,
    shadow: GlassShadow.light,
  );

  static const frosted = GlassEffect(
    preset: GlassPreset.frosted,
    blurRadius: 20,
    opacity: 0.35,
    border: GlassBorder.thin,
    shadow: GlassShadow.light,
  );

  static const condensed = GlassEffect(
    preset: GlassPreset.condensed,
    blurRadius: 32,
    opacity: 0.7,
    border: GlassBorder.bright,
    shadow: GlassShadow.heavy,
  );
}

// ─── 星空主题 ──────────────────────────────────────────
class StarfieldTheme {
  final String name;
  final StarColor diaryColor;
  final StarColor todoColor;
  final StarColor doneTodoColor;
  final StarColor tagColor;
  final Color linkColor;
  final Color backgroundTop;
  final Color backgroundBottom;
  final double particleDensity;
  final GlassEffect glassEffect;

  const StarfieldTheme({
    required this.name,
    required this.diaryColor,
    required this.todoColor,
    required this.doneTodoColor,
    required this.tagColor,
    required this.linkColor,
    required this.backgroundTop,
    required this.backgroundBottom,
    this.particleDensity = 1.0,
    required this.glassEffect,
  });

  StarfieldTheme copyWith({
    String? name,
    StarColor? diaryColor,
    StarColor? todoColor,
    StarColor? doneTodoColor,
    StarColor? tagColor,
    Color? linkColor,
    Color? backgroundTop,
    Color? backgroundBottom,
    double? particleDensity,
    GlassEffect? glassEffect,
  }) {
    return StarfieldTheme(
      name: name ?? this.name,
      diaryColor: diaryColor ?? this.diaryColor,
      todoColor: todoColor ?? this.todoColor,
      doneTodoColor: doneTodoColor ?? this.doneTodoColor,
      tagColor: tagColor ?? this.tagColor,
      linkColor: linkColor ?? this.linkColor,
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      particleDensity: particleDensity ?? this.particleDensity,
      glassEffect: glassEffect ?? this.glassEffect,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'diaryColor': diaryColor.toJson(),
        'todoColor': todoColor.toJson(),
        'doneTodoColor': doneTodoColor.toJson(),
        'tagColor': tagColor.toJson(),
        'linkColor': linkColor.value.toRadixString(16),
        'backgroundTop': backgroundTop.value.toRadixString(16),
        'backgroundBottom': backgroundBottom.value.toRadixString(16),
        'particleDensity': particleDensity,
        'glassEffect': glassEffect.toJson(),
      };

  factory StarfieldTheme.fromJson(Map<String, dynamic> json) {
    return StarfieldTheme(
      name: json['name'] as String,
      diaryColor: StarColor.fromJson(json['diaryColor'] as Map<String, dynamic>),
      todoColor: StarColor.fromJson(json['todoColor'] as Map<String, dynamic>),
      doneTodoColor:
          StarColor.fromJson(json['doneTodoColor'] as Map<String, dynamic>),
      tagColor: StarColor.fromJson(json['tagColor'] as Map<String, dynamic>),
      linkColor:
          Color(int.parse(json['linkColor'] as String, radix: 16)),
      backgroundTop:
          Color(int.parse(json['backgroundTop'] as String, radix: 16)),
      backgroundBottom:
          Color(int.parse(json['backgroundBottom'] as String, radix: 16)),
      particleDensity: json['particleDensity'] as double? ?? 1.0,
      glassEffect:
          GlassEffect.fromJson(json['glassEffect'] as Map<String, dynamic>),
    );
  }
}

// ─── 预设主题 ───────────────────────────────────────────
class PresetThemes {
  static const deepSpace = StarfieldTheme(
    name: '深空蓝',
    diaryColor: StarColor(color: Color(0xFFFFD700)),       // 金黄
    todoColor: StarColor(color: Color(0xFF00BFFF)),        // 冰蓝
    doneTodoColor: StarColor(color: Color(0xFF8899AA)),    // 灰白
    tagColor: StarColor(color: Color(0xFF9C27B0)),         // 紫色
    linkColor: Color(0x40FFFFFF),
    backgroundTop: Color(0xFF0A0E27),
    backgroundBottom: Color(0xFF1A1A3E),
    particleDensity: 1.0,
    glassEffect: GlassEffect.frosted,
  );

  static const sakura = StarfieldTheme(
    name: '樱花粉',
    diaryColor: StarColor(color: Color(0xFFFFB7C5)),
    todoColor: StarColor(color: Color(0xFF87CEEB)),
    doneTodoColor: StarColor(color: Color(0xFFC0C0C0)),
    tagColor: StarColor(color: Color(0xFFFF69B4)),
    linkColor: Color(0x40FFB7C5),
    backgroundTop: Color(0xFF1A0A1E),
    backgroundBottom: Color(0xFF2D1B36),
    particleDensity: 1.2,
    glassEffect: GlassEffect.light,
  );

  static const forest = StarfieldTheme(
    name: '森林绿',
    diaryColor: StarColor(color: Color(0xFF98FB98)),
    todoColor: StarColor(color: Color(0xFFADD8E6)),
    doneTodoColor: StarColor(color: Color(0xFF8FBC8F)),
    tagColor: StarColor(color: Color(0xFF32CD32)),
    linkColor: Color(0x4098FB98),
    backgroundTop: Color(0xFF0A1A0E),
    backgroundBottom: Color(0xFF1B2D1F),
    particleDensity: 0.8,
    glassEffect: GlassEffect.frosted,
  );

  static const lava = StarfieldTheme(
    name: '熔岩红',
    diaryColor: StarColor(color: Color(0xFFFF6347)),
    todoColor: StarColor(color: Color(0xFFFFA500)),
    doneTodoColor: StarColor(color: Color(0xFF8B4513)),
    tagColor: StarColor(color: Color(0xFFFF4500)),
    linkColor: Color(0x40FF6347),
    backgroundTop: Color(0xFF1A0A0A),
    backgroundBottom: Color(0xFF2D1B1B),
    particleDensity: 0.9,
    glassEffect: GlassEffect.condensed,
  );

  static const aurora = StarfieldTheme(
    name: '极光青',
    diaryColor: StarColor(color: Color(0xFF00FFCC)),
    todoColor: StarColor(color: Color(0xFF7B68EE)),
    doneTodoColor: StarColor(color: Color(0xFF5F9EA0)),
    tagColor: StarColor(color: Color(0xFF00CED1)),
    linkColor: Color(0x4000FFCC),
    backgroundTop: Color(0xFF0A1A1A),
    backgroundBottom: Color(0xFF1B2D2D),
    particleDensity: 1.1,
    glassEffect: GlassEffect.light,
  );

  static const autumn = StarfieldTheme(
    name: '暖秋橙',
    diaryColor: StarColor(color: Color(0xFFFFA07A)),
    todoColor: StarColor(color: Color(0xFFDEB887)),
    doneTodoColor: StarColor(color: Color(0xFFBC8F8F)),
    tagColor: StarColor(color: Color(0xFFFF8C00)),
    linkColor: Color(0x40FFA07A),
    backgroundTop: Color(0xFF1A140A),
    backgroundBottom: Color(0xFF2D241B),
    particleDensity: 1.0,
    glassEffect: GlassEffect.frosted,
  );

  static const pureNight = StarfieldTheme(
    name: '纯夜黑',
    diaryColor: StarColor(color: Color(0xFFFFFFFF)),
    todoColor: StarColor(color: Color(0xFFCCCCCC)),
    doneTodoColor: StarColor(color: Color(0xFF666666)),
    tagColor: StarColor(color: Color(0xFFAAAAAA)),
    linkColor: Color(0x30FFFFFF),
    backgroundTop: Color(0xFF000000),
    backgroundBottom: Color(0xFF0A0A0A),
    particleDensity: 0.6,
    glassEffect: GlassEffect.none,
  );

  static const List<StarfieldTheme> all = [
    deepSpace,
    sakura,
    forest,
    lava,
    aurora,
    autumn,
    pureNight,
  ];
}
