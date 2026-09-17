import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Une "feuille" de dessin bien plus grande que l'écran : combinée à
/// [InteractiveViewer] côté appelant, ça donne l'effet d'une page quasi
/// infinie dans laquelle on peut se déplacer et zoomer pour dessiner
/// un détail précis.
const kSketchSheetSize = Size(3000, 3000);

class Stroke {
  final List<Offset> points;
  const Stroke(this.points);
}

/// Widget de dessin au doigt (ou au stylet). Les traits capturés sont
/// exposés via [strokes] pour que l'appelant les rattache à la note ;
/// leur interprétation/vectorisation par l'IA viendra dans une étape
/// suivante (voir backend/services/sketch_interpreter.py).
class SketchCanvas extends StatefulWidget {
  final List<Stroke> initialStrokes;
  final ValueChanged<List<Stroke>> onChanged;

  const SketchCanvas({
    super.key,
    required this.initialStrokes,
    required this.onChanged,
  });

  @override
  State<SketchCanvas> createState() => SketchCanvasState();
}

class SketchCanvasState extends State<SketchCanvas> {
  late List<Stroke> _strokes;
  List<Offset>? _currentStroke;

  @override
  void initState() {
    super.initState();
    _strokes = List.of(widget.initialStrokes);
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onChanged(_strokes);
  }

  void clear() {
    setState(() => _strokes = []);
    widget.onChanged(_strokes);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _currentStroke = [details.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _currentStroke = [..._currentStroke!, details.localPosition]);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.length > 1) {
      _strokes = [..._strokes, Stroke(_currentStroke!)];
      widget.onChanged(_strokes);
    }
    setState(() => _currentStroke = null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: kSketchSheetSize.width,
        height: kSketchSheetSize.height,
        child: CustomPaint(
          painter: _SketchPainter(
            strokes: _currentStroke == null
                ? _strokes
                : [..._strokes, Stroke(_currentStroke!)],
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<Stroke> strokes;

  _SketchPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    // Grille légère pour matérialiser la feuille, repère visuel pendant
    // le déplacement/zoom.
    final gridPaint = Paint()
      ..color = AppColors.neutralBorder
      ..strokeWidth = 1;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final strokePaint = Paint()
      ..color = AppColors.inkDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
