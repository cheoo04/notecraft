import 'package:go_router/go_router.dart';

import '../../features/document_result/view/document_result_screen.dart';
import '../../features/generation/generation_request_args.dart';
import '../../features/generation/view/generation_config_screen.dart';
import '../../features/generation/view/generation_progress_screen.dart';
import '../../features/history/view/history_screen.dart';
import '../../features/history/view/note_detail_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/note_editor/view/note_editor_screen.dart';
import '../../features/note_editor/view/sketch_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../models/document.dart';
import '../../models/note.dart';

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
        path: '/note/sketch',
        builder: (context, state) => const SketchScreen(),
      ),
      GoRoute(
        path: '/note/detail',
        builder: (context, state) =>
            NoteDetailScreen(note: state.extra as Note),
      ),
      GoRoute(
        path: '/note/config',
        builder: (context, state) =>
            GenerationConfigScreen(note: state.extra as Note?),
      ),
      GoRoute(
        path: '/note/progress',
        builder: (context, state) =>
            GenerationProgressScreen(args: state.extra as GenerationRequestArgs?),
      ),
      GoRoute(
        path: '/document/:id',
        builder: (context, state) =>
            DocumentResultScreen(document: state.extra as GeneratedDocument?),
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
