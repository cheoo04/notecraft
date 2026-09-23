abstract class TranscriptionService {
  /// Transcrit un fichier audio (≤ 30 min) en texte.
  Future<String> transcribe(String audioFilePath);
}

class TranscriptionServiceImpl implements TranscriptionService {
  @override
  Future<String> transcribe(String audioFilePath) {
    // Connexion au micro-service Whisper du backend planifiée avec le module audio
    throw UnsupportedError(
        'La transcription automatique sera activée avec le module Whisper.');
  }
}
