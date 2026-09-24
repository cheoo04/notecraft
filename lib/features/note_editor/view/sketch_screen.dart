// lib/features/note_editor/view/sketch_screen.dart

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../../../core/theme/app_theme.dart';

enum SketchTool { pen, text, eraser }

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

class _SketchLabel {
  final String text;
  final Offset position;
  _SketchLabel(this.text, this.position);

  Map<String, dynamic> toJson() => {
        'text': text,
        'x': position.dx,
        'y': position.dy,
      };

  factory _SketchLabel.fromJson(Map<String, dynamic> json) => _SketchLabel(
        json['text'] as String,
        Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
      );
}

class SketchScreen extends StatefulWidget {
  final String? existingPngPath;

  const SketchScreen({super.key, this.existingPngPath});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_SketchStroke> _strokes = [];
  final List<_SketchLabel> _labels = [];

  SketchTool _currentTool = SketchTool.pen;
  bool _saving = false;
  bool _loading = true;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPngPath;
    _id = existing == null
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : existing
            .split('/')
            .last
            .replaceFirst('sketch_', '')
            .replaceFirst('.png', '');
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = widget.existingPngPath;
    if (existing != null) {
      try {
        final jsonPath = existing.replaceFirst('.png', '.json');
        final file = File(jsonPath);
        if (await file.exists()) {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is List) {
            _strokes.addAll(
              decoded.map(
                  (s) => _SketchStroke.fromJson(s as Map<String, dynamic>)),
            );
          } else if (decoded is Map<String, dynamic>) {
            final strokeList = decoded['strokes'] as List? ?? [];
            _strokes.addAll(
              strokeList.map(
                  (s) => _SketchStroke.fromJson(s as Map<String, dynamic>)),
            );
            final labelList = decoded['labels'] as List? ?? [];
            _labels.addAll(
              labelList
                  .map((l) => _SketchLabel.fromJson(l as Map<String, dynamic>)),
            );
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == SketchTool.text) {
      _promptAddText(details.localPosition);
      return;
    }

    setState(() {
      _strokes.add(
        _SketchStroke(
          [details.localPosition],
          erase: _currentTool == SketchTool.eraser,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTool == SketchTool.text) return;
    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _promptAddText(Offset position) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ajouter une étiquette / texte',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Capteur IoT, Tri rapide, Nœud A...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _labels.add(_SketchLabel(text, position));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Placer le texte'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      } else if (_labels.isNotEmpty) {
        _labels.removeLast();
      }
    });
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _strokes.clear();
      _labels.clear();
    });
  }

  Future<void> _finish() async {
    if (_strokes.isEmpty && _labels.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jsonPath = '${dir.path}/sketch_$_id.json';
      final pngPath = '${dir.path}/sketch_$_id.png';

      final data = {
        'strokes': _strokes.map((s) => s.toJson()).toList(),
        'labels': _labels.map((l) => l.toJson()).toList(),
      };
      await File(jsonPath).writeAsString(jsonEncode(data));

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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existingPngPath == null
              ? 'Nouveau schéma'
              : 'Modifier le schéma',
        ),
        actions: [
          // Outil Crayon
          IconButton(
            icon: Icon(
              Icons.draw_outlined,
              color: _currentTool == SketchTool.pen
                  ? AppColors.accentTeal
                  : AppColors.textMuted,
            ),
            tooltip: 'Tracé libre',
            onPressed: () => setState(() => _currentTool = SketchTool.pen),
          ),
          // Outil Texte Clavier
          IconButton(
            icon: Icon(
              Icons.text_fields_outlined,
              color: _currentTool == SketchTool.text
                  ? AppColors.accentTeal
                  : AppColors.textMuted,
            ),
            tooltip: 'Ajouter du texte au clavier',
            onPressed: () => setState(() => _currentTool = SketchTool.text),
          ),
          // Outil Gomme
          IconButton(
            icon: Icon(
              Icons.auto_fix_normal,
              color: _currentTool == SketchTool.eraser
                  ? AppColors.accentTeal
                  : AppColors.textMuted,
            ),
            tooltip: 'Gomme',
            onPressed: () => setState(() => _currentTool = SketchTool.eraser),
          ),
          // Annuler
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler',
            onPressed: (_strokes.isEmpty && _labels.isEmpty) ? null : _undo,
          ),
          // Tout effacer
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tout effacer',
            onPressed: (_strokes.isEmpty && _labels.isEmpty) ? null : _clear,
          ),
          // Terminer / Sauvegarder
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
                  icon: const Icon(Icons.check, color: AppColors.accentTeal),
                  tooltip: 'Valider le schéma',
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
              painter: _CombinedSketchPainter(
                strokes: _strokes,
                labels: _labels,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _CombinedSketchPainter extends CustomPainter {
  final List<_SketchStroke> strokes;
  final List<_SketchLabel> labels;

  _CombinedSketchPainter({required this.strokes, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dessine les traits (crayon et gomme)
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.erase ? Colors.white : AppColors.inkDark
        ..strokeWidth = stroke.erase ? 24 : 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // 2. Dessine les étiquettes de texte tapées au clavier
    for (final label in labels) {
      final textSpan = TextSpan(
        text: label.text,
        style: const TextStyle(
          color: AppColors.inkDark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Dessine un petit fond blanc discret sous le texte pour la lisibilité
      final bgRect = Rect.fromLTWH(
        label.position.dx - 4,
        label.position.dy - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      textPainter.paint(canvas, label.position);
    }
  }

  @override
  bool shouldRepaint(covariant _CombinedSketchPainter oldDelegate) => true;
}
