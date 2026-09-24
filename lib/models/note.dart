// lib/models/note.dart

/// Une note saisie par l'utilisateur : texte, esquisses, photos, audios multiples
/// et métadonnées de cours (matière, tags).
class Note {
  final String id;
  final String title;
  final String subject;
  final String? rawText;
  final List<String> rawSketchPaths;
  final String? sketchSvgPath;
  final List<String> imagePaths;
  final List<String> audioPaths;
  final Duration? audioDuration;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    this.subject = 'Général',
    this.rawText,
    this.rawSketchPaths = const [],
    this.sketchSvgPath,
    this.imagePaths = const [],
    this.audioPaths = const [],
    this.audioDuration,
    required this.createdAt,
  });

  Note copyWith({
    String? title,
    String? subject,
    String? rawText,
    List<String>? rawSketchPaths,
    String? sketchSvgPath,
    List<String>? imagePaths,
    List<String>? audioPaths,
    Duration? audioDuration,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      rawText: rawText ?? this.rawText,
      rawSketchPaths: rawSketchPaths ?? this.rawSketchPaths,
      sketchSvgPath: sketchSvgPath ?? this.sketchSvgPath,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPaths: audioPaths ?? this.audioPaths,
      audioDuration: audioDuration ?? this.audioDuration,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subject': subject,
        'rawText': rawText,
        'rawSketchPaths': rawSketchPaths,
        'sketchSvgPath': sketchSvgPath,
        'imagePaths': imagePaths,
        'audioPaths': audioPaths,
        'audioDurationMs': audioDuration?.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    // Retrocompatibilite : si audioPaths n'existe pas, on recupere l'ancien audioPath unique
    List<String> loadedAudioPaths = [];
    if (map['audioPaths'] != null) {
      loadedAudioPaths = (map['audioPaths'] as List).cast<String>();
    } else if (map['audioPath'] != null &&
        (map['audioPath'] as String).isNotEmpty) {
      loadedAudioPaths = [map['audioPath'] as String];
    }

    return Note(
      id: id,
      title: map['title'] as String? ?? 'Note sans titre',
      subject: map['subject'] as String? ?? 'Général',
      rawText: map['rawText'] as String?,
      rawSketchPaths:
          (map['rawSketchPaths'] as List?)?.cast<String>() ?? const [],
      sketchSvgPath: map['sketchSvgPath'] as String?,
      imagePaths: (map['imagePaths'] as List?)?.cast<String>() ?? const [],
      audioPaths: loadedAudioPaths,
      audioDuration: map['audioDurationMs'] != null
          ? Duration(milliseconds: map['audioDurationMs'] as int)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
