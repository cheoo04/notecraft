import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/generation/controller/generation_config_controller.dart';
import '../models/document.dart';

enum ExportFormat { pdf, word, svg }

abstract class ExportService {
  /// PDF généré nativement côté Flutter (package `pdf`).
  /// Retourne le chemin du fichier sauvegardé.
  Future<String> exportToPdf(GeneratedDocument document);

  /// Word généré côté backend (python-docx), plus fiable que les libs Dart.
  Future<String> exportToWord(GeneratedDocument document);

  /// Export des schémas nettoyés en SVG.
  Future<List<String>> exportSketchesToSvg(GeneratedDocument document);
}

class ExportServiceImpl implements ExportService {
  @override
  Future<String> exportToPdf(GeneratedDocument document) async {
    final pdf = pw.Document();
    final content = document.content ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              formatLabel(document.format),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        build: (context) => _buildMarkdownLite(content),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notecraft_${document.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
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

/// Conversion Markdown → widgets PDF volontairement simple (V1) : titres,
/// puces, séparateurs et **gras** en ligne. Le LaTeX (\[ ... \]) n'est pas
/// rendu ici (affiché tel quel) — le rendu formules restera à faire pour
/// le PDF si besoin, séparément du rendu à l'écran (gpt_markdown) qui,
/// lui, le gère déjà.
List<pw.Widget> _buildMarkdownLite(String content) {
  final widgets = <pw.Widget>[];
  final lines = content.split('\n');

  for (final rawLine in lines) {
    final line = rawLine.trimRight();

    if (line.trim().isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      continue;
    }

    if (line.trim() == '---') {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Divider(color: PdfColors.grey400),
      ));
      continue;
    }

    final headerMatch = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(line);
    if (headerMatch != null) {
      final level = headerMatch.group(1)!.length;
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
        child: pw.Text(
          headerMatch.group(2)!,
          style: pw.TextStyle(
            fontSize: level == 1 ? 18 : (level == 2 ? 15 : 13),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ));
      continue;
    }

    // Une ligne entièrement en **gras** (souvent utilisée comme titre de
    // section dans nos prompts) est traitée comme un sous-titre.
    final boldLineMatch = RegExp(r'^\*\*(.+)\*\*:?$').firstMatch(line.trim());
    if (boldLineMatch != null) {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
        child: pw.Text(
          boldLineMatch.group(1)!,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ));
      continue;
    }

    final bulletMatch = RegExp(r'^[-*]\s+(.*)').firstMatch(line.trim());
    if (bulletMatch != null) {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  '),
            pw.Expanded(child: _inlineText(bulletMatch.group(1)!)),
          ],
        ),
      ));
      continue;
    }

    widgets.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: _inlineText(line),
    ));
  }

  return widgets;
}

/// Gère le **gras** en ligne (pas d'italique/imbrication pour rester
/// simple) en découpant le texte en segments normaux/gras.
pw.Widget _inlineText(String text) {
  final spans = <pw.TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var last = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(pw.TextSpan(text: text.substring(last, match.start)));
    }
    spans.add(pw.TextSpan(
      text: match.group(1),
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    ));
    last = match.end;
  }
  if (last < text.length) {
    spans.add(pw.TextSpan(text: text.substring(last)));
  }

  return pw.RichText(
    text: pw.TextSpan(style: const pw.TextStyle(fontSize: 11), children: spans),
  );
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportServiceImpl();
});
