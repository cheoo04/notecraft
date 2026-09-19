import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_service.dart';

class SketchResult {
  final String svgPath;
  final String description;
  const SketchResult({required this.svgPath, required this.description});
}

abstract class SketchService {
  /// Envoie le PNG d'un croquis (voir SketchScreen) au backend, qui le
  /// reconstruit en SVG via un modèle vision. Sauvegarde le SVG reçu
  /// localement et retourne son chemin, plus une description
  /// structurée des relations (à injecter dans le prompt de
  /// génération).
  Future<SketchResult> vectorize(String pngPath);
}

class SketchServiceImpl implements SketchService {
  final Dio _dio;

  SketchServiceImpl(this._dio);

  @override
  Future<SketchResult> vectorize(String pngPath) async {
    final bytes = await File(pngPath).readAsBytes();
    final imageBase64 = base64Encode(bytes);

    final response = await _dio.post(
      '/sketch/',
      data: {'image_base64': imageBase64},
    );

    final data = response.data as Map<String, dynamic>;
    final svg = data['svg'] as String;
    final description = data['description'] as String;

    final dir = await getApplicationDocumentsDirectory();
    // Même id que le PNG source (sketch_<id>.png -> sketch_<id>.svg),
    // pour garder le lien visuel entre le croquis brut et sa version
    // nettoyée sans avoir besoin d'un champ supplémentaire.
    final id = pngPath.split('/').last.replaceFirst('.png', '');
    final svgPath = '${dir.path}/sketch_$id.svg';
    await File(svgPath).writeAsString(svg);

    return SketchResult(svgPath: svgPath, description: description);
  }
}

final sketchServiceProvider = Provider<SketchService>((ref) {
  return SketchServiceImpl(ref.watch(dioProvider));
});
