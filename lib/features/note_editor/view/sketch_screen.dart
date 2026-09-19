import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Écran de dessin à main levée pour un schéma/croquis.
/// Si [existingPngPath] est fourni, recharge les traits sauvegardés
/// (fichier .json à côté du .png) pour permettre de compléter/gommer un
/// schéma déjà commencé, plutôt que de repartir de zéro.
class SketchScreen extends StatefulWidget {
  final String? existingPngPath;

  const SketchScreen({super.key, this.existingPngPath});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchStroke {
  final List<Offset> points;
  final bool erase;
  _SketchStroke(this.points, {this.erase = false});

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'erase': erase,
      };

  factory _SketchStroke.fromJson(Map<String, dynamic> json) => _SketchStroke(
        (json['points'] as List)
            .map((p) => Offset(
                  (p['x'] as num).toDouble(),
                  (p['y'] as num).toDouble(),
                ))
            .toList(),
        erase: json['erase'] as bool? ?? false,
      );
}

class _SketchScreenState extends State<SketchScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_SketchStroke> _strokes = [];
  bool _erasing = false;
  bool _saving = false;
  bool _loading = true;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPngPath;
    _id = existing == null
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : existing.split('/').last.replaceFirst('sketch_', '').replaceFirst('.png', '');
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = widget.existingPngPath;
    if (existing != null) {
      try {
        final jsonPath = existing.replaceFirst('.png', '.json');
        final file = File(jsonPath);
        if (await file.exists()) {
          final raw = jsonDecode(await file.readAsString()) as List;
          _strokes.addAll(
            raw.map((s) => _SketchStroke.fromJson(s as Map<String, dynamic>)),
          );
        }
      } catch (_) {
        // Traits perdus (fichier manquant/corrompu) : on repart d'un
        // canvas vide plutôt que de planter l'écran.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _strokes.add(_SketchStroke([details.localPosition], erase: _erasing));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
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
      final dir = await getApplicationDocumentsDirectory();
      final jsonPath = '${dir.path}/sketch_$_id.json';
      final pngPath = '${dir.path}/sketch_$_id.png';

      await File(jsonPath).writeAsString(
        jsonEncode(_strokes.map((s) => s.toJson()).toList()),
      );

      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(pngPath).writeAsBytes(byteData!.buffer.asUint8List());

      if (!mounted) return;
      Navigator.of(context).pop(pngPath);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPngPath == null ? 'Nouveau schéma' : 'Modifier le schéma'),
        actions: [
          IconButton(
            icon: Icon(_erasing ? Icons.edit_outlined : Icons.auto_fix_normal),
            tooltip: _erasing ? 'Repasser en dessin' : 'Gomme',
            onPressed: () => setState(() => _erasing = !_erasing),
          ),
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
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.erase ? Colors.white : Colors.black
        ..strokeWidth = stroke.erase ? 24 : 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
