# Stargazer

日记与待办融合的星空图谱应用

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Riverpod
- **本地数据库**: Drift (SQLite)
- **图谱渲染**: CustomPainter + Fragment Shader
- **同步**: 插件化架构（Git / WebDAV / REST API）

## 平台支持

- Android
- Windows
- （未来）iOS / macOS / Linux

## 快速开始

```bash
flutter pub get
flutter run -d windows   # Windows 端
flutter run -d android   # Android 端
```

## 项目结构

```
lib/
├── core/
│   ├── models/          # 数据模型
│   ├── storage/         # 本地存储（Drift 数据库）
│   ├── sync/            # 同步引擎抽象 + 插件接口
│   └── theme/           # 星空主题系统（颜色 + 毛玻璃）
├── features/
│   ├── journal/         # 日记模块
│   ├── todo/            # 待办模块
│   ├── starmap/         # 星空图谱（渲染 + 交互 + Shader）
│   └── sync_ui/         # 同步设置界面
├── shared/
│   ├── widgets/         # 通用组件（FrostedCard 等）
│   ├── utils/           # 工具函数
│   └── router/          # 路由配置
── main.dart
```

## 开发阶段

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 0 | 项目骨架 + 主题系统 | ✅ 已完成 |
| Phase 1 | 数据层（数据库 + Markdown 文件 + Git + 同步插件） | ✅ 已完成 |
| Phase 2 | 日记 + 待办核心功能 + 外观设置 | ✅ 已完成 |
| Phase 3 | 星空图谱渲染 + 特效 + Shader 背景 | ✅ 已完成 |
| Phase 4 | 同步系统 UI 完善 | ✅ 已完成 |
| Phase 5 | 特色功能（去年今日/情绪统计/截图分享/Obsidian 导入） | ✅ 已完成 |
| Phase 6 | 平台适配 + 发布 | ✅ 已完成 |
| Phase 7 | 搜索增强 + 快速捕获 + Markdown 预览 | ✅ 已完成 |
| Phase 8 | 星尘粒子系统 + 星尘调色盘 + 心情天气 + 声音景观 + 时间旅行 + 星空画廊 + AI 星座命名 + 数据导出 | ✅ 已完成 |

## License

Private
