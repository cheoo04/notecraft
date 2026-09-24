// lib/services/export_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_io/io.dart';

import '../features/generation/controller/generation_config_controller.dart';
import '../models/document.dart';

enum ExportFormat { pdf, word, svg }

abstract class ExportService {
  /// Genere les octets PDF directement en memoire (compatible Web et Mobile)
  Future<Uint8List> generatePdfBytes(GeneratedDocument document);

  /// Sauvegarde locale pour mobile
  Future<String> exportToPdf(GeneratedDocument document);

  Future<String> exportToWord(GeneratedDocument document);

  Future<List<String>> exportSketchesToSvg(GeneratedDocument document);
}

class ExportServiceImpl implements ExportService {
  @override
  Future<Uint8List> generatePdfBytes(GeneratedDocument document) async {
    final pdf = pw.Document();
    var content = document.content ?? '';

    // Normalisation typographique pour la police standard du PDF
    content = content
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‑', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('•', '*')
        .replaceAll('⁴', '^4')
        .replaceAll('³', '^3')
        .replaceAll('²', '^2');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              formatLabel(document.format),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        build: (context) => _buildMarkdownLite(content),
      ),
    );

    return await pdf.save();
  }

  @override
  Future<String> exportToPdf(GeneratedDocument document) async {
    final bytes = await generatePdfBytes(document);
    if (kIsWeb) return '';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/notecraft_${document.id}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<String> exportToWord(GeneratedDocument document) {
    throw UnsupportedError(
        'L\'export Word sera disponible dans la prochaine version.');
  }

  @override
  Future<List<String>> exportSketchesToSvg(GeneratedDocument document) {
    return Future.value(document.cleanedSketchSvgPaths);
  }
}

List<pw.Widget> _buildMarkdownLite(String content) {
  final widgets = <pw.Widget>[];
  final mathBlock = RegExp(r'\\\[(.*?)\\\]', dotAll: true);
  var lastEnd = 0;

  for (final match in mathBlock.allMatches(content)) {
    if (match.start > lastEnd) {
      widgets.addAll(_buildTextLines(content.substring(lastEnd, match.start)));
    }
    widgets.add(_buildDisplayMath(match.group(1) ?? ''));
    lastEnd = match.end;
  }
  if (lastEnd < content.length) {
    widgets.addAll(_buildTextLines(content.substring(lastEnd)));
  }

  return widgets;
}

List<pw.Widget> _buildTextLines(String content) {
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

    final boldLineMatch = RegExp(r'^\*\*(.+)\*\*:?$').firstMatch(line.trim());
    if (boldLineMatch != null) {
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
        child: pw.Text(
          boldLineMatch.group(1)!,
          style:
              const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
            pw.Text('*  '),
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
      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
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

sealed class _MathNode {}

class _MathText extends _MathNode {
  final String text;
  _MathText(this.text);
}

class _MathSup extends _MathNode {
  final List<_MathNode> content;
  _MathSup(this.content);
}

class _MathSub extends _MathNode {
  final List<_MathNode> content;
  _MathSub(this.content);
}

class _MathFrac extends _MathNode {
  final List<_MathNode> numerator;
  final List<_MathNode> denominator;
  _MathFrac(this.numerator, this.denominator);
}

List<_MathNode> _parseMath(String src) {
  final nodes = <_MathNode>[];
  var i = 0;
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isNotEmpty) {
      nodes.add(_MathText(buffer.toString()));
      buffer.clear();
    }
  }

  String readGroupOrChar() {
    while (i < src.length && src[i] == ' ') {
      i++;
    }
    if (i < src.length && src[i] == '{') {
      i++;
      var depth = 1;
      final start = i;
      while (i < src.length && depth > 0) {
        if (src[i] == '{') depth++;
        if (src[i] == '}') depth--;
        if (depth > 0) i++;
      }
      final inner = src.substring(start, i);
      if (i < src.length) i++;
      return inner;
    } else if (i < src.length) {
      final c = src[i];
      i++;
      return c;
    }
    return '';
  }

  while (i < src.length) {
    final c = src[i];

    if (c == '\\') {
      flush();
      i++;
      final cmdStart = i;
      while (i < src.length && RegExp(r'[a-zA-Z]').hasMatch(src[i])) {
        i++;
      }
      final cmd = src.substring(cmdStart, i);

      if (cmd.isEmpty) {
        if (i < src.length) i++;
        continue;
      }

      while (i < src.length && src[i] == ' ') {
        i++;
      }

      if (cmd == 'frac') {
        final numStr = readGroupOrChar();
        final denStr = readGroupOrChar();
        nodes.add(_MathFrac(_parseMath(numStr), _parseMath(denStr)));
      } else if (cmd == 'text' || cmd == 'mathrm' || cmd == 'mathbf') {
        nodes.add(_MathText(readGroupOrChar()));
      } else {
        nodes.add(_MathText(cmd));
      }
    } else if (c == '^') {
      flush();
      i++;
      nodes.add(_MathSup(_parseMath(readGroupOrChar())));
    } else if (c == '_') {
      flush();
      i++;
      nodes.add(_MathSub(_parseMath(readGroupOrChar())));
    } else if (c == '{' || c == '}') {
      i++;
    } else {
      buffer.write(c);
      i++;
    }
  }
  flush();
  return nodes;
}

pw.Widget _buildDisplayMath(String tex) {
  final nodes = _parseMath(tex.trim());
  return pw.Container(
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    child: pw.Wrap(
      alignment: pw.WrapAlignment.center,
      crossAxisAlignment: pw.WrapCrossAlignment.center,
      children: nodes.map((n) => _renderMathNode(n, 12)).toList(),
    ),
  );
}

pw.Widget _renderMathNode(_MathNode node, double fontSize) {
  if (node is _MathText) {
    return pw.Text(
      node.text,
      style: pw.TextStyle(fontSize: fontSize, fontStyle: pw.FontStyle.italic),
    );
  }
  if (node is _MathSup) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: _renderMathGroup(node.content, fontSize * 0.7),
    );
  }
  if (node is _MathSub) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5),
      child: _renderMathGroup(node.content, fontSize * 0.7),
    );
  }
  if (node is _MathFrac) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _renderMathGroup(node.numerator, fontSize * 0.85),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            height: 0.8,
            color: PdfColors.black,
          ),
          _renderMathGroup(node.denominator, fontSize * 0.85),
        ],
      ),
    );
  }
  return pw.SizedBox();
}

pw.Widget _renderMathGroup(List<_MathNode> nodes, double fontSize) {
  if (nodes.isEmpty) return pw.SizedBox();
  if (nodes.every((n) => n is _MathText)) {
    final text = nodes.map((n) => (n as _MathText).text).join();
    return pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: fontSize, fontStyle: pw.FontStyle.italic),
    );
  }
  return pw.Wrap(
    alignment: pw.WrapAlignment.center,
    crossAxisAlignment: pw.WrapCrossAlignment.center,
    children: nodes.map((n) => _renderMathNode(n, fontSize)).toList(),
  );
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportServiceImpl();
});
