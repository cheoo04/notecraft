// lib/features/note_editor/controller/note_editor_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:universal_io/io.dart';

import '../../../models/note.dart';
import '../../settings/controller/settings_controller.dart';

class NoteEditorState {
  final String? existingNoteId;
  final DateTime? existingCreatedAt;
  final String title;
  final String subject;
  final String content;
  final List<String> sketchPaths;
  final List<String> imagePaths;
  final List<String> audioPaths;
  final Duration? audioDuration;
  final bool isRecording;
  final int recordingSeconds;

  const NoteEditorState({
    this.existingNoteId,
    this.existingCreatedAt,
    this.title = '',
    this.subject = 'Informatique',
    this.content = '',
    this.sketchPaths = const [],
    this.imagePaths = const [],
    this.audioPaths = const [],
    this.audioDuration,
    this.isRecording = false,
    this.recordingSeconds = 0,
  });

  bool get canProceed =>
      content.trim().isNotEmpty ||
      sketchPaths.isNotEmpty ||
      imagePaths.isNotEmpty ||
      audioPaths.isNotEmpty;

  String get formattedRecordingTime {
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds / 30:00';
  }

  NoteEditorState copyWith({
    String? existingNoteId,
    DateTime? existingCreatedAt,
    String? title,
    String? subject,
    String? content,
    List<String>? sketchPaths,
    List<String>? imagePaths,
    List<String>? audioPaths,
    Duration? audioDuration,
    bool? isRecording,
    int? recordingSeconds,
  }) {
    return NoteEditorState(
      existingNoteId: existingNoteId ?? this.existingNoteId,
      existingCreatedAt: existingCreatedAt ?? this.existingCreatedAt,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      sketchPaths: sketchPaths ?? this.sketchPaths,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPaths: audioPaths ?? this.audioPaths,
      audioDuration: audioDuration ?? this.audioDuration,
      isRecording: isRecording ?? this.isRecording,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
    );
  }
}

class NoteEditorController extends Notifier<NoteEditorState> {
  Timer? _recordingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  NoteEditorState build() {
    ref.onDispose(() {
      _recordingTimer?.cancel();
      _audioRecorder.dispose();
    });

    final defaultSubject =
        ref.read(settingsControllerProvider).profile.favoriteSubject;
    return NoteEditorState(
      subject: defaultSubject.isNotEmpty ? defaultSubject : 'Général',
    );
  }

  void initForNote(Note? note) {
    if (note == null) {
      final defaultSubject =
          ref.read(settingsControllerProvider).profile.favoriteSubject;
      state = NoteEditorState(
        subject: defaultSubject.isNotEmpty ? defaultSubject : 'Général',
      );
      return;
    }

    state = NoteEditorState(
      existingNoteId: note.id,
      existingCreatedAt: note.createdAt,
      title: note.title,
      subject: note.subject,
      content: note.rawText ?? '',
      sketchPaths: note.rawSketchPaths,
      imagePaths: note.imagePaths,
      audioPaths: note.audioPaths,
      audioDuration: note.audioDuration,
    );
  }

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void updateSubject(String value) {
    state = state.copyWith(subject: value);
  }

  void updateContent(String value) {
    state = state.copyWith(content: value);
  }

  void addSketch(String path) {
    if (state.sketchPaths.contains(path)) return;
    state = state.copyWith(sketchPaths: [...state.sketchPaths, path]);
  }

  void removeSketch(String path) {
    state = state.copyWith(
      sketchPaths: state.sketchPaths.where((p) => p != path).toList(),
    );
  }

  void addImage(String path) {
    if (state.imagePaths.contains(path)) return;
    state = state.copyWith(imagePaths: [...state.imagePaths, path]);
  }

  void removeImage(String path) {
    state = state.copyWith(
      imagePaths: state.imagePaths.where((p) => p != path).toList(),
    );
  }

  Future<bool> startRecording() async {
    if (state.isRecording) return false;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return false;

    _recordingTimer?.cancel();

    try {
      String filePath = '';
      RecordConfig config;

      if (kIsWeb) {
        config = const RecordConfig(encoder: AudioEncoder.opus, bitRate: 64000);
        filePath = '';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        config =
            const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000);
      }

      await _audioRecorder.start(config, path: filePath);

      state = state.copyWith(
        isRecording: true,
        recordingSeconds: 0,
      );

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.recordingSeconds >= 1800) {
          stopRecording();
        } else {
          state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopRecording() async {
    _recordingTimer?.cancel();

    try {
      final realPath = await _audioRecorder.stop();
      if (realPath != null && realPath.isNotEmpty) {
        state = state.copyWith(
          isRecording: false,
          audioPaths: [...state.audioPaths, realPath],
        );
      } else {
        state = state.copyWith(isRecording: false);
      }
    } catch (_) {
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> removeAudio(String path) async {
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    state = state.copyWith(
      audioPaths: state.audioPaths.where((p) => p != path).toList(),
    );
  }

  Note buildNote() {
    final now = DateTime.now();
    return Note(
      id: state.existingNoteId ?? now.microsecondsSinceEpoch.toString(),
      title:
          state.title.trim().isEmpty ? 'Note sans titre' : state.title.trim(),
      subject: state.subject.trim().isEmpty ? 'Général' : state.subject.trim(),
      rawText: state.content.trim(),
      rawSketchPaths: state.sketchPaths,
      imagePaths: state.imagePaths,
      audioPaths: state.audioPaths,
      audioDuration: state.audioDuration,
      createdAt: state.existingCreatedAt ?? now,
    );
  }
}

final noteEditorControllerProvider =
    NotifierProvider<NoteEditorController, NoteEditorState>(
  NoteEditorController.new,
);
