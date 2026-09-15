import 'dart:ui';

abstract class SketchService {
  /// Envoie une esquisse à main levée (points/traits capturés localement
  /// via CustomPainter) et reçoit en retour un schéma nettoyé au format SVG.
  Future<String> vectorize(List<List<Offset>> strokes);
}

class SketchServiceImpl implements SketchService {
  @override
  Future<String> vectorize(List<List<Offset>> strokes) {
    // TODO: envoyer les tracés au backend (sketch_interpreter.py)
    throw UnimplementedError();
  }
}
