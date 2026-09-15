/// Une note d'origine saisie par l'utilisateur : texte, esquisse,
/// image(s) et/ou un audio (≤ 30 min).
class Note {
  final String id;
  final String title;
  final String? rawText;
  final String? sketchSvgPath;
  final List<String> imagePaths;
  final String? audioPath;
  final Duration? audioDuration;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    this.rawText,
    this.sketchSvgPath,
    this.imagePaths = const [],
    this.audioPath,
    this.audioDuration,
    required this.createdAt,
  });
}
