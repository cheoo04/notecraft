// lib/features/settings/controller/settings_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';
import '../../../models/user_preferences.dart';

class SettingsState {
  final WritingTone tone;
  final DocumentFormat format;
  final bool keepAudioFiles;
  final int affineUsed;
  final int affineTotal;

  const SettingsState({
    this.tone = WritingTone.academique,
    this.format = DocumentFormat.ficheDeRevision,
    this.keepAudioFiles = true,
    this.affineUsed = 18,
    this.affineTotal = 50,
  });

  SettingsState copyWith({
    WritingTone? tone,
    DocumentFormat? format,
    bool? keepAudioFiles,
    int? affineUsed,
    int? affineTotal,
  }) {
    return SettingsState(
      tone: tone ?? this.tone,
      format: format ?? this.format,
      keepAudioFiles: keepAudioFiles ?? this.keepAudioFiles,
      affineUsed: affineUsed ?? this.affineUsed,
      affineTotal: affineTotal ?? this.affineTotal,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void updateTone(WritingTone tone) {
    state = state.copyWith(tone: tone);
  }

  void updateFormat(DocumentFormat format) {
    state = state.copyWith(format: format);
  }

  void toggleKeepAudio(bool value) {
    state = state.copyWith(keepAudioFiles: value);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
