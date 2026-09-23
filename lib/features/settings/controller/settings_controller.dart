// lib/features/settings/controller/settings_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';
import '../../../models/user_preferences.dart';
import '../../../models/user_profile.dart';
import '../../../services/storage_service.dart';

class SettingsState {
  final UserProfile profile;
  final int realAffineUsed;
  final bool isLoading;

  const SettingsState({
    this.profile = const UserProfile(),
    this.realAffineUsed = 0,
    this.isLoading = false,
  });

  SettingsState copyWith({
    UserProfile? profile,
    int? realAffineUsed,
    bool? isLoading,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      realAffineUsed: realAffineUsed ?? this.realAffineUsed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(() => refreshQuotaUsage());
    return const SettingsState();
  }

  Future<void> refreshQuotaUsage() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final notes = await storage.getNotes();
      int count = 0;
      for (final n in notes) {
        final docs = await storage.getDocumentsForNote(n.id);
        count += docs.where((d) => d.mode == GenerationMode.affine).length;
      }
      state = state.copyWith(realAffineUsed: count);
    } catch (_) {}
  }

  void updateName(String firstName, String lastName) {
    state = state.copyWith(
      profile: state.profile.copyWith(firstName: firstName, lastName: lastName),
    );
  }

  void updateSchool(String school) {
    state = state.copyWith(
      profile: state.profile.copyWith(school: school),
    );
  }

  void updateFavoriteSubject(String subject) {
    state = state.copyWith(
      profile: state.profile.copyWith(favoriteSubject: subject),
    );
  }

  void updateTone(WritingTone tone) {
    state = state.copyWith(
      profile: state.profile.copyWith(tone: tone),
    );
  }

  void updateFormat(DocumentFormat format) {
    state = state.copyWith(
      profile: state.profile.copyWith(defaultFormat: format),
    );
  }

  void toggleKeepAudio(bool value) {
    state = state.copyWith(
      profile: state.profile.copyWith(keepAudioFiles: value),
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
