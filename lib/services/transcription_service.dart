// lib/services/transcription_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';

abstract class TranscriptionService {
  Future<String> transcribe(String audioFilePath);
}

class TranscriptionServiceImpl implements TranscriptionService {
  final Dio _dio;

  TranscriptionServiceImpl(this._dio);

  @override
  Future<String> transcribe(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      return '';
    }

    final bytes = await file.readAsBytes();
    final audioBase64 = base64Encode(bytes);

    final response = await _dio.post(
      '/transcribe/',
      data: {
        'audio_base64': audioBase64,
        'filename': audioFilePath.split('/').last,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }
}

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionServiceImpl(ref.watch(dioProvider));
});
