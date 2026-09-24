// lib/features/note_editor/controller/note_editor_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../models/note.dart';
import '../../settings/controller/settings_controller.dart';

class NoteEditorState {
  final String title;
  final String subject;
  final String content;
  final List<String> sketchPaths;
  final List<String> imagePaths;
  final String? audioPath;
  final Duration? audioDuration;
  final bool isRecording;
  final int recordingSeconds;

  const NoteEditorState({
    this.title = '',
    this.subject = 'Informatique',
    this.content = '',
    this.sketchPaths = const [],
    this.imagePaths = const [],
    this.audioPath,
    this.audioDuration,
    this.isRecording = false,
    this.recordingSeconds = 0,
  });

  bool get canProceed =>
      content.trim().isNotEmpty ||
      sketchPaths.isNotEmpty ||
      imagePaths.isNotEmpty ||
      audioPath != null;

  String get formattedRecordingTime {
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds / 30:00';
  }

  NoteEditorState copyWith({
    String? title,
    String? subject,
    String? content,
    List<String>? sketchPaths,
    List<String>? imagePaths,
    String? audioPath,
    Duration? audioDuration,
    bool? isRecording,
    int? recordingSeconds,
    bool clearAudio = false,
  }) {
    return NoteEditorState(
      title: title ?? this.title,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      sketchPaths: sketchPaths ?? this.sketchPaths,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      audioDuration: clearAudio ? null : (audioDuration ?? this.audioDuration),
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

  // Enregistrement reel avec le micro du telephone
  Future<bool> startRecording() async {
    if (state.isRecording) return false;

    // 1. Demande de permission micro
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return false;

    _recordingTimer?.cancel();

    try {
      // 2. Creation d'un vrai fichier dans le dossier documents de l'application
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 3. Demarrage de l'enregistrement en AAC (.m4a)
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: filePath,
      );

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
      // Arrete l'enregistreur et recupere le chemin reel du fichier audio
      final realPath = await _audioRecorder.stop();
      final duration = Duration(seconds: state.recordingSeconds);

      if (realPath != null && await File(realPath).exists()) {
        state = state.copyWith(
          isRecording: false,
          audioPath: realPath,
          audioDuration: duration,
        );
      } else {
        state = state.copyWith(isRecording: false);
      }
    } catch (_) {
      state = state.copyWith(isRecording: false);
    }
  }

  Future<void> deleteAudio() async {
    _recordingTimer?.cancel();

    if (state.isRecording) {
      await _audioRecorder.stop();
    }

    if (state.audioPath != null) {
      try {
        final file = File(state.audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    state = state.copyWith(
      isRecording: false,
      recordingSeconds: 0,
      clearAudio: true,
    );
  }

  Note buildNote() {
    final now = DateTime.now();
    return Note(
      id: now.microsecondsSinceEpoch.toString(),
      title:
          state.title.trim().isEmpty ? 'Note sans titre' : state.title.trim(),
      subject: state.subject.trim().isEmpty ? 'Général' : state.subject.trim(),
      rawText: state.content.trim(),
      rawSketchPaths: state.sketchPaths,
      imagePaths: state.imagePaths,
      audioPath: state.audioPath,
      audioDuration: state.audioDuration,
      createdAt: now,
    );
  }
}

final noteEditorControllerProvider =
    NotifierProvider<NoteEditorController, NoteEditorState>(
  NoteEditorController.new,
);
