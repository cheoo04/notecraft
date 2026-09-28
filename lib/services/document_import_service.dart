// lib/services/document_import_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';

class ExtractedDocumentResult {
  final String text;
  final String? suggestedTitle;

  const ExtractedDocumentResult({required this.text, this.suggestedTitle});
}

abstract class DocumentImportService {
  Future<ExtractedDocumentResult?> pickAndExtractDocument();
}

class DocumentImportServiceImpl implements DocumentImportService {
  final Dio _dio;

  DocumentImportServiceImpl(this._dio);

  @override
  Future<ExtractedDocumentResult?> pickAndExtractDocument() async {
    // Syntaxe moderne file_picker : appel direct sans passer par .platform
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
    );

    if (file == null) return null;

    final filename = file.name;
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Fichier vide ou inaccessible.');
    }

    final lower = filename.toLowerCase();

    // Traitement local instantane pour TXT et Markdown
    if (lower.endsWith('.txt') || lower.endsWith('.md')) {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      final title = filename.split('.').first.replaceAll(RegExp(r'[_-]'), ' ');
      return ExtractedDocumentResult(text: text, suggestedTitle: title);
    }

    // Traitement backend pour PDF et Word (.docx)
    final fileBase64 = base64Encode(bytes);
    final response = await _dio.post(
      '/extract/',
      data: {
        'file_base64': fileBase64,
        'filename': filename,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return ExtractedDocumentResult(
      text: data['extracted_text'] as String? ?? '',
      suggestedTitle: data['suggested_title'] as String?,
    );
  }
}

final documentImportServiceProvider = Provider<DocumentImportService>((ref) {
  return DocumentImportServiceImpl(ref.watch(dioProvider));
});
