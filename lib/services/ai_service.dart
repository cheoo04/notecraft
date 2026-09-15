import '../models/document.dart';
import '../models/note.dart';

/// Orchestration des appels au backend pour la génération de documents.
/// Le backend (voir /backend) cache la clé API et centralise les prompts,
/// ce qui permettra de remplacer l'API externe par un modèle auto-hébergé
/// plus tard sans changer ce contrat.
abstract class AiService {
  Future<GeneratedDocument> generate({
    required Note note,
    required DocumentFormat format,
    required GenerationMode mode,
  });

  /// Pour le mode Affiné : interroge le statut d'une génération en cours.
  Future<GeneratedDocument> checkStatus(String documentId);
}

class AiServiceImpl implements AiService {
  // TODO: injecter un client Dio configuré sur l'URL du backend

  @override
  Future<GeneratedDocument> generate({
    required Note note,
    required DocumentFormat format,
    required GenerationMode mode,
  }) {
    // TODO: POST /generate
    throw UnimplementedError();
  }

  @override
  Future<GeneratedDocument> checkStatus(String documentId) {
    // TODO: GET /generate/:id/status
    throw UnimplementedError();
  }
}
