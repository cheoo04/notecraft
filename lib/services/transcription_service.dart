abstract class TranscriptionService {
  /// Transcrit un fichier audio (≤ 30 min) en texte.
  Future<String> transcribe(String audioFilePath);
}

class TranscriptionServiceImpl implements TranscriptionService {
  @override
  Future<String> transcribe(String audioFilePath) {
    // TODO: envoyer le fichier au backend (endpoint Whisper ou équivalent)
    throw UnimplementedError();
  }
}
