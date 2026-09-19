import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Écran de dessin à main levée pour un schéma/croquis.
/// V1 : un seul trait de couleur/épaisseur fixe. Pas de calque image de
/// fond, pas de formes prédéfinies — volontairement simple, la
/// reconstruction "propre" du schéma viendra de l'IA (étape suivante),
/// pas d'outils de dessin avancés ici.
class SketchScreen extends StatefulWidget {
  const SketchScreen({super.key});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchStroke {
  final List<Offset> points;
  _SketchStroke(this.points);
}

class _SketchScreenState extends State<SketchScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_SketchStroke> _strokes = [];
  bool _saving = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _strokes.add(_SketchStroke([details.localPosition]));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  Future<void> _finish() async {
    if (_strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/sketch_${DateTime.now().microsecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context).pop(path);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esquisse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler le dernier trait',
            onPressed: _strokes.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tout effacer',
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Terminer',
                  onPressed: _finish,
                ),
        ],
      ),
      body: RepaintBoundary(
        key: _boundaryKey,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: CustomPaint(
              painter: _SketchPainter(_strokes),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<_SketchStroke> strokes;
  _SketchPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
