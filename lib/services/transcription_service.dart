// lib/services/transcription_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_service.dart';

abstract class TranscriptionService {
  Future<String> transcribe(String audioFilePath);
}

class TranscriptionServiceImpl implements TranscriptionService {
  final Dio _dio;

  TranscriptionServiceImpl(this._dio);

  @override
  Future<String> transcribe(String audioFilePath) async {
    // XFile lit aussi bien les fichiers physiques Android que les URL blob Web
    final xFile = XFile(audioFilePath);
    final bytes = await xFile.readAsBytes();
    if (bytes.isEmpty) return '';

    final audioBase64 = base64Encode(bytes);
    final filename = kIsWeb ? 'audio.webm' : audioFilePath.split('/').last;

    final response = await _dio.post(
      '/transcribe/',
      data: {
        'audio_base64': audioBase64,
        'filename': filename,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }
}

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionServiceImpl(ref.watch(dioProvider));
});
