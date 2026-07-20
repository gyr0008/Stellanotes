import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:stargazer/core/theme/app_theme.dart';

void main() {
  group('StarfieldTheme', () {
    test('serialization roundtrip', () {
      final original = PresetThemes.deepSpace;
      final json = original.toJson();
      final restored = StarfieldTheme.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.diaryColor.color, original.diaryColor.color);
      expect(restored.todoColor.color, original.todoColor.color);
      expect(restored.backgroundTop, original.backgroundTop);
      expect(restored.backgroundBottom, original.backgroundBottom);
      expect(restored.particleDensity, original.particleDensity);
    });

    test('copyWith creates new instance', () {
      final original = PresetThemes.deepSpace;
      final modified = original.copyWith(
        name: '自定义',
        diaryColor: original.diaryColor.copyWith(color: const Color(0xFFFF0000)),
      );

      expect(modified.name, '自定义');
      expect(modified.diaryColor.color, const Color(0xFFFF0000));
      // 其他字段不变
      expect(modified.todoColor.color, original.todoColor.color);
    });
  });

  group('GlassEffect', () {
    test('presets have correct defaults', () {
      expect(GlassEffect.none.blurRadius, 0);
      expect(GlassEffect.light.blurRadius, 8);
      expect(GlassEffect.frosted.blurRadius, 20);
      expect(GlassEffect.condensed.blurRadius, 32);
    });

    test('serialization roundtrip', () {
      final original = GlassEffect.frosted;
      final json = original.toJson();
      final restored = GlassEffect.fromJson(json);

      expect(restored.preset, original.preset);
      expect(restored.blurRadius, original.blurRadius);
      expect(restored.opacity, original.opacity);
      expect(restored.border, original.border);
      expect(restored.shadow, original.shadow);
    });
  });

  group('PresetThemes', () {
    test('all presets are unique', () {
      final names = PresetThemes.all.map((t) => t.name).toSet();
      expect(names.length, PresetThemes.all.length);
    });

    test('all presets have valid glass effect', () {
      for (final theme in PresetThemes.all) {
        expect(theme.glassEffect.blurRadius, greaterThanOrEqualTo(0));
        expect(theme.glassEffect.opacity, greaterThanOrEqualTo(0.0));
        expect(theme.glassEffect.opacity, lessThanOrEqualTo(1.0));
      }
    });
  });
}
