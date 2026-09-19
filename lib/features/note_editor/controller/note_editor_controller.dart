import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note.dart';

class NoteEditorState {
  final String title;
  final String content;
  final List<String> sketchPaths;

  const NoteEditorState({
    this.title = '',
    this.content = '',
    this.sketchPaths = const [],
  });

  bool get canProceed => content.trim().isNotEmpty;

  NoteEditorState copyWith({
    String? title,
    String? content,
    List<String>? sketchPaths,
  }) {
    return NoteEditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      sketchPaths: sketchPaths ?? this.sketchPaths,
    );
  }
}

class NoteEditorController extends Notifier<NoteEditorState> {
  @override
  NoteEditorState build() => const NoteEditorState();

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void updateContent(String value) {
    state = state.copyWith(content: value);
  }

  /// Ajoute un nouveau schéma. Si ce chemin existe déjà dans la liste
  /// (cas d'une édition d'un schéma existant : même fichier réécrit),
  /// ne fait rien — pas de doublon.
  void addSketch(String path) {
    if (state.sketchPaths.contains(path)) return;
    state = state.copyWith(sketchPaths: [...state.sketchPaths, path]);
  }

  void removeSketch(String path) {
    state = state.copyWith(
      sketchPaths: state.sketchPaths.where((p) => p != path).toList(),
    );
  }

  /// Construit la [Note] à partir de la saisie courante.
  /// Ne doit être appelé que si [NoteEditorState.canProceed] est vrai.
  Note buildNote() {
    final now = DateTime.now();
    return Note(
      id: now.microsecondsSinceEpoch.toString(),
      title: state.title.trim().isEmpty ? 'Note sans titre' : state.title.trim(),
      rawText: state.content.trim(),
      rawSketchPaths: state.sketchPaths,
      createdAt: now,
    );
  }
}

final noteEditorControllerProvider =
    NotifierProvider<NoteEditorController, NoteEditorState>(
  NoteEditorController.new,
);
