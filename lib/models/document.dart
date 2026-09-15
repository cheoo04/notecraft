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
}
