// lib/models/user_profile.dart

import 'document.dart';
import 'user_preferences.dart';

class UserProfile {
  final String firstName;
  final String lastName;
  final String school; // Ex: ESIR - Informatique & IoT
  final String favoriteSubject;
  final WritingTone tone;
  final DocumentFormat defaultFormat;
  final bool keepAudioFiles;
  final int monthlyQuotaTotal;

  const UserProfile({
    this.firstName = 'Yah',
    this.lastName = 'K.',
    this.school = 'ESIR - Systèmes & IoT',
    this.favoriteSubject = 'Informatique',
    this.tone = WritingTone.academique,
    this.defaultFormat = DocumentFormat.resume,
    this.keepAudioFiles = true,
    this.monthlyQuotaTotal = 50,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? school,
    String? favoriteSubject,
    WritingTone? tone,
    DocumentFormat? defaultFormat,
    bool? keepAudioFiles,
    int? monthlyQuotaTotal,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      school: school ?? this.school,
      favoriteSubject: favoriteSubject ?? this.favoriteSubject,
      tone: tone ?? this.tone,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      keepAudioFiles: keepAudioFiles ?? this.keepAudioFiles,
      monthlyQuotaTotal: monthlyQuotaTotal ?? this.monthlyQuotaTotal,
    );
  }
}
