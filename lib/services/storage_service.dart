import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../models/note.dart';

/// Persistance des notes et documents.
/// V1 : Firestore directement (pas d'auth branchée encore — voir le
/// README de ce fix pour les règles de sécurité temporaires).
abstract class StorageService {
  Future<void> saveNote(Note note);
  Future<List<Note>> getNotes();
  Future<void> saveDocument(GeneratedDocument document);
  Future<List<GeneratedDocument>> getDocumentsForNote(String noteId);
}

class FirestoreStorageService implements StorageService {
  final FirebaseFirestore _db;

  FirestoreStorageService(this._db);

  CollectionReference<Map<String, dynamic>> get _notes =>
      _db.collection('notes');
  CollectionReference<Map<String, dynamic>> get _documents =>
      _db.collection('documents');

  @override
  Future<void> saveNote(Note note) async {
    await _notes.doc(note.id).set(note.toMap());
  }

  @override
  Future<List<Note>> getNotes() async {
    final snapshot =
        await _notes.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((d) => Note.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> saveDocument(GeneratedDocument document) async {
    await _documents.doc(document.id).set(document.toMap());
  }

  @override
  Future<List<GeneratedDocument>> getDocumentsForNote(String noteId) async {
    final snapshot = await _documents.where('noteId', isEqualTo: noteId).get();
    final docs = snapshot.docs
        .map((d) => GeneratedDocument.fromMap(d.id, d.data()))
        .toList();
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return FirestoreStorageService(ref.watch(firestoreProvider));
});
