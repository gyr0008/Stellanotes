/// 情绪词典
///
/// 用于本地情绪识别的关键词库。
class EmotionDictionary {
  /// 正面情绪词
  static const List<String> positive = [
    '开心', '快乐', '高兴', '幸福', '美好', '棒', '赞', '优秀', '出色',
    '喜欢', '爱', '温暖', '感动', '惊喜', '兴奋', '激动', '满足', '满意',
    '成功', '进步', '成长', '收获', '希望', '期待', '梦想', '阳光', '灿烂',
  ];

  /// 负面情绪词
  static const List<String> negative = [
    '难过', '悲伤', '痛苦', '伤心', '失望', '沮丧', '郁闷', '烦躁', '焦虑',
    '生气', '愤怒', '恼火', '讨厌', '恨', '害怕', '恐惧', '担心', '忧虑',
    '失败', '挫折', '困难', '压力', '疲惫', '累', '烦', '糟', '差', '坏',
  ];

  /// 中性情绪词
  static const List<String> neutral = [
    '平静', '普通', '一般', '正常', '还行', '可以', '不错', '还好',
    '思考', '反思', '总结', '计划', '安排', '准备', '开始', '结束',
  ];

  /// 获取文本情绪评分 (-1 到 1)
  static double analyzeEmotion(String text) {
    if (text.isEmpty) return 0;

    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positive) {
      if (text.contains(word)) positiveCount++;
    }

    for (final word in negative) {
      if (text.contains(word)) negativeCount++;
    }

    final total = positiveCount + negativeCount;
    if (total == 0) return 0;

    return (positiveCount - negativeCount) / total;
  }

  /// 获取情绪标签
  static String getEmotionLabel(String text) {
    final score = analyzeEmotion(text);
    
    if (score > 0.3) return '😊 开心';
    if (score > 0.1) return '🙂 不错';
    if (score < -0.3) return '😢 难过';
    if (score < -0.1) return '😕 一般';
    return '😐 平静';
  }
}

/// 标签提取器
///
/// 使用简单的关键词匹配和频率分析提取标签。
class TagExtractor {
  /// 常见标签词库
  static const List<String> commonTags = [
    '工作', '学习', '生活', '家庭', '朋友', '旅行', '美食', '运动',
    '读书', '电影', '音乐', '游戏', '购物', '健康', '心情', '想法',
    '计划', '目标', '梦想', '回忆', '感恩', '反思', '成长', '改变',
    '春天', '夏天', '秋天', '冬天', '早上', '中午', '晚上', '周末',
  ];

  /// 从文本中提取标签
  static List<String> extractTags(String text, {int maxTags = 5}) {
    if (text.isEmpty) return [];

    final tagScores = <String, int>{};

    // 统计标签词出现次数
    for (final tag in commonTags) {
      final matches = tag.allMatches(text).length;
      if (matches > 0) {
        tagScores[tag] = matches;
      }
    }

    // 按频率排序
    final sortedTags = tagScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(maxTags).map((e) => e.key).toList();
  }

  /// 获取标签建议
  static List<String> getSuggestions(String text) {
    final tags = extractTags(text, maxTags: 3);
    
    // 如果没有提取到标签，返回默认建议
    if (tags.isEmpty) {
      return ['生活', '心情', '想法'];
    }
    
    return tags;
  }
}
