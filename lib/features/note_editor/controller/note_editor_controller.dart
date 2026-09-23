// lib/features/note_editor/controller/note_editor_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/note.dart';

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
    this.subject = 'Physique',
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

  @override
  NoteEditorState build() {
    ref.onDispose(() => _recordingTimer?.cancel());
    return const NoteEditorState();
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

  // Gestion du dictaphone audio (30 min max)
  void startRecording() {
    if (state.isRecording) return;
    _recordingTimer?.cancel();
    state = state.copyWith(isRecording: true, recordingSeconds: 0);

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.recordingSeconds >= 1800) {
        // Limite maximale de 30 minutes atteinte
        stopRecording();
      } else {
        state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
      }
    });
  }

  void stopRecording() {
    _recordingTimer?.cancel();
    final duration = Duration(seconds: state.recordingSeconds);
    // Identifiant local de session audio
    final mockAudioPath =
        'audio_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    state = state.copyWith(
      isRecording: false,
      audioPath: mockAudioPath,
      audioDuration: duration,
    );
  }

  void deleteAudio() {
    _recordingTimer?.cancel();
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
