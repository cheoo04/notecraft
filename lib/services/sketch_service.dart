// lib/services/sketch_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'ai_service.dart';

class SketchResult {
  final String svgPath;
  final String description;
  const SketchResult({required this.svgPath, required this.description});
}

abstract class SketchService {
  Future<SketchResult> vectorize(String pngPath);
}

class SketchServiceImpl implements SketchService {
  final Dio _dio;

  SketchServiceImpl(this._dio);

  @override
  Future<SketchResult> vectorize(String pngPath) async {
    String imageBase64;

    // 1. Sur le Web ou en memoire Data-URL : pas d'appel disque
    if (pngPath.startsWith('data:image')) {
      imageBase64 = pngPath.split(',').last;
    } else {
      final bytes = await File(pngPath).readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final response = await _dio.post(
      '/sketch/',
      data: {'image_base64': imageBase64},
    );

    final data = response.data as Map<String, dynamic>;
    final svg = data['svg'] as String;
    final description = data['description'] as String;

    if (kIsWeb) {
      // Sur le Web, on conserve directement la chaine SVG
      return SketchResult(svgPath: svg, description: description);
    }

    final dir = await getApplicationDocumentsDirectory();
    final id = pngPath.split('/').last.replaceFirst('.png', '');
    final svgPath = '${dir.path}/sketch_$id.svg';
    await File(svgPath).writeAsString(svg);

    return SketchResult(svgPath: svgPath, description: description);
  }
}

final sketchServiceProvider = Provider<SketchService>((ref) {
  return SketchServiceImpl(ref.watch(dioProvider));
});
