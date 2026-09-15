import '../models/document.dart';
import '../models/note.dart';

/// Persistance des notes et documents.
/// V1 : Isar en local pour l'accès hors-ligne à l'historique,
/// synchronisé avec Firebase/Supabase pour la sauvegarde cloud.
abstract class StorageService {
  Future<void> saveNote(Note note);
  Future<List<Note>> getNotes();
  Future<void> saveDocument(GeneratedDocument document);
  Future<List<GeneratedDocument>> getDocumentsForNote(String noteId);
}

class StorageServiceImpl implements StorageService {
  @override
  Future<void> saveNote(Note note) => throw UnimplementedError();

  @override
  Future<List<Note>> getNotes() => throw UnimplementedError();

  @override
  Future<void> saveDocument(GeneratedDocument document) =>
      throw UnimplementedError();

  @override
  Future<List<GeneratedDocument>> getDocumentsForNote(String noteId) =>
      throw UnimplementedError();
}
