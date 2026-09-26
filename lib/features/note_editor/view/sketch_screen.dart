// lib/features/note_editor/view/sketch_screen.dart

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../../../core/theme/app_theme.dart';

enum SketchTool { pen, text, eraser }

// Cache memoire pour la reedition des schemas sur navigateur Web
final Map<String, String> _webSketchJsonStore = {};

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
  String text;
  Offset position;
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

  Rect getBounds() {
    final width = text.length * 9.5 + 24;
    return Rect.fromLTWH(position.dx - 8, position.dy - 8, width, 36);
  }
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
  _SketchLabel? _draggedLabel;
  Offset _dragDelta = Offset.zero;

  bool _saving = false;
  bool _loading = true;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPngPath;
    _id = existing == null
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : (existing.startsWith('data:')
            ? DateTime.now().microsecondsSinceEpoch.toString()
            : existing
                .split('/')
                .last
                .replaceFirst('sketch_', '')
                .replaceFirst('.png', ''));
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = widget.existingPngPath;
    if (existing != null) {
      try {
        String? jsonRaw;
        if (kIsWeb) {
          jsonRaw = _webSketchJsonStore[_id];
        } else {
          final jsonPath = existing.replaceFirst('.png', '.json');
          final file = File(jsonPath);
          if (await file.exists()) {
            jsonRaw = await file.readAsString();
          }
        }

        if (jsonRaw != null) {
          final decoded = jsonDecode(jsonRaw);
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

  _SketchLabel? _findLabelAt(Offset point) {
    for (int i = _labels.length - 1; i >= 0; i--) {
      if (_labels[i].getBounds().contains(point)) {
        return _labels[i];
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == SketchTool.text) {
      final touchedLabel = _findLabelAt(details.localPosition);
      if (touchedLabel != null) {
        HapticFeedback.selectionClick();
        _draggedLabel = touchedLabel;
        _dragDelta = details.localPosition - touchedLabel.position;
      }
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
    if (_currentTool == SketchTool.text) {
      if (_draggedLabel != null) {
        setState(() {
          _draggedLabel!.position = details.localPosition - _dragDelta;
        });
      }
      return;
    }

    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _draggedLabel = null;
  }

  void _onTapCanvas(TapUpDetails details) {
    if (_currentTool != SketchTool.text) return;

    final touchedLabel = _findLabelAt(details.localPosition);
    if (touchedLabel != null) {
      _showEditLabelDialog(touchedLabel);
    } else {
      _showCreateLabelDialog(details.localPosition);
    }
  }

  void _showCreateLabelDialog(Offset position) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nouveau texte / étiquette',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Routeur, Capteur, Nœud A...',
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
            child: const Text('Placer'),
          ),
        ],
      ),
    );
  }

  void _showEditLabelDialog(_SketchLabel label) {
    final textController = TextEditingController(text: label.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Modifier l\'étiquette',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _labels.remove(label);
              });
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  label.text = text;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
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
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final data = {
        'strokes': _strokes.map((s) => s.toJson()).toList(),
        'labels': _labels.map((l) => l.toJson()).toList(),
      };
      final jsonString = jsonEncode(data);

      // 1. Cas Web : capture memoire binaire pure (aucune dependance fichier disque)
      if (kIsWeb) {
        _webSketchJsonStore[_id] = jsonString;
        final base64Image = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64Image';
        if (!mounted) return;
        Navigator.of(context).pop(dataUrl);
        return;
      }

      // 2. Cas Mobile : ecriture normale dans les documents locaux
      final dir = await getApplicationDocumentsDirectory();
      final jsonPath = '${dir.path}/sketch_$_id.json';
      final pngPath = '${dir.path}/sketch_$_id.png';

      await File(jsonPath).writeAsString(jsonString);
      await File(pngPath).writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context).pop(pngPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de validation du schéma : $e')),
      );
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
          IconButton(
            icon: Icon(
              Icons.draw_outlined,
              color: _currentTool == SketchTool.pen
                  ? AppColors.accentTeal
                  : AppColors.textMuted,
            ),
            tooltip: 'Crayon (tracé libre)',
            onPressed: () => setState(() => _currentTool = SketchTool.pen),
          ),
          IconButton(
            icon: Icon(
              Icons.text_fields_outlined,
              color: _currentTool == SketchTool.text
                  ? AppColors.accentTeal
                  : AppColors.textMuted,
            ),
            tooltip: 'Texte (toucher pour placer ou glisser pour déplacer)',
            onPressed: () => setState(() => _currentTool = SketchTool.text),
          ),
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
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler',
            onPressed: (_strokes.isEmpty && _labels.isEmpty) ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tout effacer',
            onPressed: (_strokes.isEmpty && _labels.isEmpty) ? null : _clear,
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
            onPanEnd: _onPanEnd,
            onTapUp: _onTapCanvas,
            child: CustomPaint(
              painter: _CombinedSketchPainter(
                strokes: _strokes,
                labels: _labels,
                isTextMode: _currentTool == SketchTool.text,
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
  final bool isTextMode;

  _CombinedSketchPainter({
    required this.strokes,
    required this.labels,
    required this.isTextMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

      final bgRect = Rect.fromLTWH(
        label.position.dx - 6,
        label.position.dy - 3,
        textPainter.width + 12,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );

      if (isTextMode) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
          Paint()
            ..color = AppColors.accentTeal.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      textPainter.paint(canvas, label.position);
    }
  }

  @override
  bool shouldRepaint(covariant _CombinedSketchPainter oldDelegate) => true;
}
