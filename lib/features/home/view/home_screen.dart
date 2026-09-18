import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_format_helper.dart';

import '../../../models/note.dart';
import '../../../services/storage_service.dart';

/// Écran 1 — Accueil & prise de notes rapide.
/// V1 : liste des 5 notes les plus récentes. Barre de recherche et
/// capture rapide viendront une fois l'historique complet en place.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes notes & synthèses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: ref.read(storageServiceProvider).getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = (snapshot.data ?? const []).take(5).toList();
          if (notes.isEmpty) {
            return const Center(
              child: Text('Aucune note encore — appuie sur + pour commencer'),
            );
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
                onTap: () => context.push('/note/detail', extra: note),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/note/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
