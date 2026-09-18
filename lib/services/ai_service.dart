import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../models/note.dart';

/// Adresse du backend, réglable au lancement sans toucher au code :
///   flutter run                                            → local (adb reverse)
///   flutter run --dart-define=API_BASE_URL=https://ton-projet.vercel.app  → Vercel
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://backend-beryl-two-39.vercel.app',
);

abstract class AiService {
  Future<GeneratedDocument> generate({
    required Note note,
    required DocumentFormat format,
    required GenerationMode mode,
  });
}

class AiServiceImpl implements AiService {
  final Dio _dio;

  AiServiceImpl(this._dio);

  @override
  Future<GeneratedDocument> generate({
    required Note note,
    required DocumentFormat format,
    required GenerationMode mode,
  }) async {
    final response = await _dio.post(
      '/generate/',
      data: {
        'note_title': note.title,
        'note_content': note.rawText ?? '',
        'format': _formatToJson(format),
        'mode': mode == GenerationMode.express ? 'express' : 'affine',
      },
    );

    final data = response.data as Map<String, dynamic>;
    return GeneratedDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      noteId: note.id,
      format: format,
      mode: mode,
      status: DocumentStatus.pret,
      content: data['content'] as String?,
      createdAt: DateTime.now(),
    );
  }
}

String _formatToJson(DocumentFormat format) {
  switch (format) {
    case DocumentFormat.resume:
      return 'resume';
    case DocumentFormat.rapport:
      return 'rapport';
    case DocumentFormat.expose:
      return 'expose';
    case DocumentFormat.planDeCours:
      return 'plan_de_cours';
    case DocumentFormat.ficheDeRevision:
      return 'fiche_de_revision';
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      // Le mode affiné (deux passes côté backend) peut prendre du temps.
      receiveTimeout: const Duration(minutes: 3),
    ),
  );
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiServiceImpl(ref.watch(dioProvider));
});
