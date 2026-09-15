import '../../../models/document.dart';
import '../../../models/note.dart';

/// Regroupe ce qui doit être transmis à l'écran de progression :
/// la note d'origine, le format choisi et le mode de traitement.
class GenerationRequestArgs {
  final Note note;
  final DocumentFormat format;
  final GenerationMode mode;

  const GenerationRequestArgs({
    required this.note,
    required this.format,
    required this.mode,
  });
}
