import 'package:go_router/go_router.dart';

import '../../features/document_result/view/document_result_screen.dart';
import '../../features/generation/view/generation_config_screen.dart';
import '../../features/generation/view/generation_progress_screen.dart';
import '../../features/history/view/history_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/note_editor/view/note_editor_screen.dart';
import '../../features/settings/view/settings_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/note/new',
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/note/config',
        builder: (context, state) => const GenerationConfigScreen(),
      ),
      GoRoute(
        path: '/note/progress',
        builder: (context, state) => const GenerationProgressScreen(),
      ),
      GoRoute(
        path: '/document/:id',
        builder: (context, state) => const DocumentResultScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
