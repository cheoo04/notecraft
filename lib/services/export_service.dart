import '../models/document.dart';

enum ExportFormat { pdf, word, svg }

abstract class ExportService {
  /// PDF généré nativement côté Flutter (package `pdf`).
  Future<String> exportToPdf(GeneratedDocument document);

  /// Word généré côté backend (python-docx), plus fiable que les libs Dart.
  Future<String> exportToWord(GeneratedDocument document);

  /// Export des schémas nettoyés en SVG.
  Future<List<String>> exportSketchesToSvg(GeneratedDocument document);
}

class ExportServiceImpl implements ExportService {
  @override
  Future<String> exportToPdf(GeneratedDocument document) {
    // TODO: utiliser package:pdf + package:printing
    throw UnimplementedError();
  }

  @override
  Future<String> exportToWord(GeneratedDocument document) {
    // TODO: POST /export/word au backend
    throw UnimplementedError();
  }

  @override
  Future<List<String>> exportSketchesToSvg(GeneratedDocument document) {
    return Future.value(document.cleanedSketchSvgPaths);
  }
}
