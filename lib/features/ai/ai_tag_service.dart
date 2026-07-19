import 'dart:convert';
import 'package:http/http.dart' as http;
import 'emotion_dictionary.dart';

/// AI 标签服务
///
/// 提供本地和云端两种标签分析方式。
class AITagService {
  /// 本地分析模式
  static const String modeLocal = 'local';
  
  /// 云端分析模式（需要 API Key）
  static const String modeCloud = 'cloud';

  String _mode = modeLocal;
  String? _apiKey;
  String? _apiUrl;

  AITagService() {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    // TODO: 从 SharedPreferences 加载设置
    _mode = modeLocal;
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // TODO: 保存到 SharedPreferences
  }

  /// 设置分析模式
  void setMode(String mode) {
    _mode = mode;
    _saveSettings();
  }

  /// 设置 API 配置
  void setApiConfig(String? apiKey, String? apiUrl) {
    _apiKey = apiKey;
    _apiUrl = apiUrl;
    _saveSettings();
  }

  /// 分析文本，返回标签和情绪
  Future<AnalysisResult> analyze(String text) async {
    if (_mode == modeCloud && _apiKey != null && _apiUrl != null) {
      return await _cloudAnalyze(text);
    } else {
      return _localAnalyze(text);
    }
  }

  /// 本地分析
  AnalysisResult _localAnalyze(String text) {
    final tags = TagExtractor.extractTags(text, maxTags: 5);
    final emotionScore = EmotionDictionary.analyzeEmotion(text);
    final emotionLabel = EmotionDictionary.getEmotionLabel(text);
    final suggestions = TagExtractor.getSuggestions(text);

    return AnalysisResult(
      tags: tags,
      emotionScore: emotionScore,
      emotionLabel: emotionLabel,
      suggestions: suggestions,
      mode: modeLocal,
    );
  }

  /// 云端分析
  Future<AnalysisResult> _cloudAnalyze(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'text': text,
          'task': 'tag_and_emotion_analysis',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AnalysisResult(
          tags: List<String>.from(data['tags'] ?? []),
          emotionScore: (data['emotion_score'] ?? 0).toDouble(),
          emotionLabel: data['emotion_label'] ?? '😐 平静',
          suggestions: List<String>.from(data['suggestions'] ?? []),
          mode: modeCloud,
        );
      } else {
        // 云端失败，降级到本地
        return _localAnalyze(text);
      }
    } catch (e) {
      // 网络错误，降级到本地
      return _localAnalyze(text);
    }
  }
}

/// 分析结果
class AnalysisResult {
  final List<String> tags;
  final double emotionScore;
  final String emotionLabel;
  final List<String> suggestions;
  final String mode;

  AnalysisResult({
    required this.tags,
    required this.emotionScore,
    required this.emotionLabel,
    required this.suggestions,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
    'tags': tags,
    'emotion_score': emotionScore,
    'emotion_label': emotionLabel,
    'suggestions': suggestions,
    'mode': mode,
  };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      tags: List<String>.from(json['tags'] ?? []),
      emotionScore: (json['emotion_score'] ?? 0).toDouble(),
      emotionLabel: json['emotion_label'] ?? '😐 平静',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      mode: json['mode'] ?? 'local',
    );
  }
}
