// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
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
import '../widgets/main_scaffold_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Navigation basse persistante
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          // Branche 0 : Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branche 1 : Historique
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          // Branche 2 : Réglages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Routes modales ou plein écran (couvrant la barre basse)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/note/new',
        builder: (context, state) =>
            NoteEditorScreen(existingNote: state.extra as Note?),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/note/sketch',
        builder: (context, state) =>
            SketchScreen(existingPngPath: state.extra as String?),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/note/detail',
        builder: (context, state) =>
            NoteDetailScreen(note: state.extra as Note),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/note/config',
        builder: (context, state) =>
            GenerationConfigScreen(note: state.extra as Note?),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/note/progress',
        builder: (context, state) => GenerationProgressScreen(
            args: state.extra as GenerationRequestArgs?),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/document/:id',
        builder: (context, state) =>
            DocumentResultScreen(document: state.extra as GeneratedDocument?),
      ),
    ],
  );
}
