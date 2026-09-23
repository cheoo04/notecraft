// lib/models/user_preferences.dart

import 'document.dart';

enum WritingTone { academique, professionnel, decontracte }

class UserPreferences {
  final WritingTone defaultTone;
  final DocumentFormat defaultFormat;
  final GenerationMode defaultMode;
  final bool keepAudioFiles;

  const UserPreferences({
    this.defaultTone = WritingTone.academique,
    this.defaultFormat = DocumentFormat.resume,
    this.defaultMode = GenerationMode.express,
    this.keepAudioFiles = true,
  });
}
