// lib/services/ocr_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';

abstract class OcrService {
  Future<String> extractTextFromImage(String imagePath);
}

class OcrServiceImpl implements OcrService {
  final Dio _dio;

  OcrServiceImpl(this._dio);

  @override
  Future<String> extractTextFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return '';

    final bytes = await file.readAsBytes();
    final imageBase64 = base64Encode(bytes);

    final response = await _dio.post(
      '/ocr/',
      data: {'image_base64': imageBase64},
    );

    final data = response.data as Map<String, dynamic>;
    return data['extracted_text'] as String? ?? '';
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrServiceImpl(ref.watch(dioProvider));
});
