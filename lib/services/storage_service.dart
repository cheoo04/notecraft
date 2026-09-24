// lib/services/storage_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../models/note.dart';

abstract class StorageService {
  Future<void> saveNote(Note note);
  Future<List<Note>> getNotes();
  Stream<List<Note>> watchNotes();
  Future<void> deleteNote(String noteId);

  Future<void> saveDocument(GeneratedDocument document);
  Future<List<GeneratedDocument>> getDocumentsForNote(String noteId);
  Stream<List<GeneratedDocument>> watchDocumentsForNote(String noteId);
  Future<void> deleteDocument(String documentId);
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
    final snapshot = await _notes.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((d) => Note.fromMap(d.id, d.data())).toList();
  }

  @override
  Stream<List<Note>> watchNotes() {
    return _notes.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((d) => Note.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
    final snapshot = await _documents.where('noteId', isEqualTo: noteId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
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

  @override
  Stream<List<GeneratedDocument>> watchDocumentsForNote(String noteId) {
    return _documents
        .where('noteId', isEqualTo: noteId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((d) => GeneratedDocument.fromMap(d.id, d.data()))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _documents.doc(documentId).delete();
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return FirestoreStorageService(ref.watch(firestoreProvider));
});

// Providers Stream temps reel
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(storageServiceProvider).watchNotes();
});

final documentsStreamProvider =
    StreamProvider.family<List<GeneratedDocument>, String>((ref, noteId) {
  return ref.watch(storageServiceProvider).watchDocumentsForNote(noteId);
});
