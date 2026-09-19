/// Une note d'origine saisie par l'utilisateur : texte, esquisse(s),
/// image(s) et/ou un audio (≤ 30 min).
class Note {
  final String id;
  final String title;
  final String? rawText;

  /// Chemins locaux des croquis bruts (PNG aplatis), un par schéma. Les
  /// traits éditables (pour pouvoir rouvrir/gommer/compléter) sont
  /// sauvegardés à côté en .json (même nom, autre extension) par
  /// SketchScreen — pas besoin de les référencer ici.
  final List<String> rawSketchPaths;

  /// SVG nettoyé une fois la reconstruction IA effectuée (étape 3).
  final String? sketchSvgPath;

  final List<String> imagePaths;
  final String? audioPath;
  final Duration? audioDuration;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    this.rawText,
    this.rawSketchPaths = const [],
    this.sketchSvgPath,
    this.imagePaths = const [],
    this.audioPath,
    this.audioDuration,
    required this.createdAt,
  });

  Note copyWith({String? rawText}) {
    return Note(
      id: id,
      title: title,
      rawText: rawText ?? this.rawText,
      rawSketchPaths: rawSketchPaths,
      sketchSvgPath: sketchSvgPath,
      imagePaths: imagePaths,
      audioPath: audioPath,
      audioDuration: audioDuration,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'rawText': rawText,
        'rawSketchPaths': rawSketchPaths,
        'sketchSvgPath': sketchSvgPath,
        'imagePaths': imagePaths,
        'audioPath': audioPath,
        'audioDurationMs': audioDuration?.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromMap(String id, Map<String, dynamic> map) => Note(
        id: id,
        title: map['title'] as String? ?? 'Note sans titre',
        rawText: map['rawText'] as String?,
        rawSketchPaths:
            (map['rawSketchPaths'] as List?)?.cast<String>() ?? const [],
        sketchSvgPath: map['sketchSvgPath'] as String?,
        imagePaths:
            (map['imagePaths'] as List?)?.cast<String>() ?? const [],
        audioPath: map['audioPath'] as String?,
        audioDuration: map['audioDurationMs'] != null
            ? Duration(milliseconds: map['audioDurationMs'] as int)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
