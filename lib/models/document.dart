enum DocumentFormat { resume, rapport, expose, planDeCours, ficheDeRevision }

enum GenerationMode { express, affine }

enum DocumentStatus { enAttente, enCours, pret, echec }

/// Un document généré par l'IA à partir d'une [Note].
class GeneratedDocument {
  final String id;
  final String noteId;
  final DocumentFormat format;
  final GenerationMode mode;
  final DocumentStatus status;
  final String? content;
  final List<String> cleanedSketchSvgPaths;
  final DateTime createdAt;

  const GeneratedDocument({
    required this.id,
    required this.noteId,
    required this.format,
    required this.mode,
    required this.status,
    this.content,
    this.cleanedSketchSvgPaths = const [],
    required this.createdAt,
  });

  GeneratedDocument copyWith({
    String? content,
    List<String>? cleanedSketchSvgPaths,
  }) {
    return GeneratedDocument(
      id: id,
      noteId: noteId,
      format: format,
      mode: mode,
      status: status,
      content: content ?? this.content,
      cleanedSketchSvgPaths: cleanedSketchSvgPaths ?? this.cleanedSketchSvgPaths,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'format': format.name,
        'mode': mode.name,
        'status': status.name,
        'content': content,
        'cleanedSketchSvgPaths': cleanedSketchSvgPaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedDocument.fromMap(String id, Map<String, dynamic> map) =>
      GeneratedDocument(
        id: id,
        noteId: map['noteId'] as String,
        format: DocumentFormat.values.byName(map['format'] as String),
        mode: GenerationMode.values.byName(map['mode'] as String),
        status: DocumentStatus.values.byName(map['status'] as String),
        content: map['content'] as String?,
        cleanedSketchSvgPaths:
            (map['cleanedSketchSvgPaths'] as List?)?.cast<String>() ??
                const [],
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
