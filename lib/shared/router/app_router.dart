import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/journal/journal_page.dart';
import '../../features/journal/widgets/journal_editor_page.dart';
import '../../features/journal/widgets/markdown_renderer.dart';
import '../../features/todo/todo_page.dart';
import '../../features/starmap/starmap_page.dart';
import '../../features/starmap/widgets/time_travel_page.dart';
import '../../features/starmap/widgets/daily_wallpaper_page.dart';
import '../../features/starmap/widgets/constellation_naming_page.dart';
import '../../features/starmap/particles/particle_color_settings.dart';
import '../../features/starmap/soundscape/soundscape_page.dart';
import '../../features/sync_ui/sync_settings_page.dart';
import '../../features/sync_ui/appearance_settings_page.dart';
import '../../features/sync_ui/git_sync_config_page.dart';
import '../../features/sync_ui/webdav_sync_config_page.dart';
import '../../features/journal/widgets/on_this_day_page.dart';
import '../../features/journal/widgets/mood_statistics_page.dart';
import '../../features/journal/widgets/obsidian_import_page.dart';
import '../../features/shared/windows_settings_page.dart';
import '../../features/shared/android_settings_page.dart';
import '../../features/shared/data_export_page.dart';
import '../../features/shared/auto_update_service.dart';
import '../../features/search/search_page.dart';
import '../../features/search/quick_capture_service.dart';

/// 路由配置
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/starmap',
    routes: [
      // 底部导航的四个主页面
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: JournalPage()),
          ),
          GoRoute(
            path: '/todo',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodoPage()),
          ),
          GoRoute(
            path: '/starmap',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StarmapPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SyncSettingsPage()),
          ),
        ],
      ),

      // 日记详情
      GoRoute(
        path: '/journal/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return JournalDetailPage(entryId: id);
        },
      ),

      // 新建日记
      GoRoute(
        path: '/journal/new',
        builder: (context, state) => const JournalEditorPage(),
      ),

      // 编辑日记
      GoRoute(
        path: '/journal/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return JournalEditorPage(entryId: id);
        },
      ),

      // 外观设置
      GoRoute(
        path: '/settings/appearance',
        builder: (context, state) => const AppearanceSettingsPage(),
      ),

      // 同步设置子页面
      GoRoute(
        path: '/settings/sync/github',
        builder: (context, state) => const GitSyncConfigPage(),
      ),
      GoRoute(
        path: '/settings/sync/webdav',
        builder: (context, state) => const WebDAVSyncConfigPage(),
      ),
      GoRoute(
        path: '/settings/sync/selfhost',
        builder: (context, state) => const SyncSettingsPage(),
      ),

      // 特色功能页面
      GoRoute(
        path: '/journal/on-this-day',
        builder: (context, state) => const OnThisDayPage(),
      ),
      GoRoute(
        path: '/journal/mood-stats',
        builder: (context, state) => const MoodStatisticsPage(),
      ),
      GoRoute(
        path: '/journal/import-obsidian',
        builder: (context, state) => const ObsidianImportPage(),
      ),

      // 平台设置
      GoRoute(
        path: '/settings/platform/windows',
        builder: (context, state) => const WindowsSettingsPage(),
      ),
      GoRoute(
        path: '/settings/platform/android',
        builder: (context, state) => const AndroidSettingsPage(),
      ),

      // 搜索
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),

      // Phase 7 新功能
      GoRoute(
        path: '/journal/markdown-editor',
        builder: (context, state) => const MarkdownEditorPage(),
      ),

      // Phase 8 新功能
      GoRoute(
        path: '/starmap/time-travel',
        builder: (context, state) => const TimeTravelPage(),
      ),
      GoRoute(
        path: '/starmap/wallpaper-gallery',
        builder: (context, state) => const WallpaperGalleryPage(),
      ),
      GoRoute(
        path: '/starmap/constellation-naming',
        builder: (context, state) => const ConstellationNamingPage(),
      ),
      GoRoute(
        path: '/settings/particle-colors',
        builder: (context, state) => const ParticleColorSettingsPage(),
      ),
      GoRoute(
        path: '/starmap/soundscape',
        builder: (context, state) => const SoundscapePage(),
      ),
      GoRoute(
        path: '/settings/data-export',
        builder: (context, state) => const DataExportPage(),
      ),
      GoRoute(
        path: '/settings/auto-update',
        builder: (context, state) => const AutoUpdateSettingsPage(),
      ),
    ],
  );
});

/// 主界面 Shell（底部导航）
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // 默认星空页

  final List<String> _routes = [
    '/journal',
    '/todo',
    '/starmap',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '日记',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            selectedIcon: Icon(Icons.stars),
            label: '星空',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
