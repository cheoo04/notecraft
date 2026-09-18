import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_format_helper.dart';

import '../../../models/note.dart';
import '../../../services/storage_service.dart';

/// Écran — Historique des notes.
/// V1 : liste simple, la plus récente en premier. Le détail par note
/// (documents associés, filtre par matière) viendra dans une itération
/// suivante, une fois qu'il y a de vraies données pour se rendre compte
/// de ce qui manque vraiment à l'usage.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: FutureBuilder<List<Note>>(
        future: ref.read(storageServiceProvider).getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur de chargement : ${snapshot.error}'),
              ),
            );
          }
          final notes = snapshot.data ?? const [];
          if (notes.isEmpty) {
            return const Center(child: Text('Aucune note pour le moment'));
          }
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(
                  formatNoteDate(note.createdAt),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
