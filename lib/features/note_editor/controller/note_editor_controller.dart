import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/note.dart';

class NoteEditorState {
  final String title;
  final String content;

  const NoteEditorState({this.title = '', this.content = ''});

  bool get canProceed => content.trim().isNotEmpty;

  NoteEditorState copyWith({String? title, String? content}) {
    return NoteEditorState(
      title: title ?? this.title,
      content: content ?? this.content,
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

  /// Construit la [Note] à partir de la saisie courante.
  /// Ne doit être appelé que si [NoteEditorState.canProceed] est vrai.
  Note buildNote() {
    final now = DateTime.now();
    return Note(
      id: now.microsecondsSinceEpoch.toString(),
      title: state.title.trim().isEmpty ? 'Note sans titre' : state.title.trim(),
      rawText: state.content.trim(),
      createdAt: now,
    );
  }
}

final noteEditorControllerProvider =
    NotifierProvider<NoteEditorController, NoteEditorState>(
  NoteEditorController.new,
);
