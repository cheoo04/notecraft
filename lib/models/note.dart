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

  Map<String, dynamic> toMap() => {
        'title': title,
        'rawText': rawText,
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
