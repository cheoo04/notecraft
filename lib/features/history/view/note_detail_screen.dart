import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format_helper.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../../../services/storage_service.dart';
import '../../generation/controller/generation_config_controller.dart';

/// Détail d'une note : son contenu, et les documents déjà générés à
/// partir d'elle (s'il y en a). Permet de relancer une génération dans
/// un autre format sans retaper la note.
class NoteDetailScreen extends ConsumerWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(note.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              note.rawText ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              formatNoteDate(note.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Documents générés',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<GeneratedDocument>>(
              future: ref.read(storageServiceProvider).getDocumentsForNote(note.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final documents = snapshot.data ?? const [];
                if (documents.isEmpty) {
                  return const Center(
                    child: Text('Aucun document généré pour cette note'),
                  );
                }
                return ListView.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(formatLabel(doc.format)),
                      subtitle: Text(
                        '${doc.mode == GenerationMode.express ? "Express" : "Affiné"} · '
                        '${formatNoteDate(doc.createdAt)}',
                      ),
                      onTap: () => context.push('/document/${doc.id}', extra: doc),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Nouveau format'),
        onPressed: () => context.push('/note/config', extra: note),
      ),
    );
  }
}
