import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/note_editor_controller.dart';

/// Écran 2 — Page blanche (V1 : saisie texte uniquement).
/// Esquisse, image et audio seront ajoutés dans une itération suivante,
/// une fois ce flux de base validé.
class NoteEditorScreen extends ConsumerWidget {
  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteEditorControllerProvider);
    final controller = ref.read(noteEditorControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle note'),
        actions: [
          TextButton(
            onPressed: state.canProceed
                ? () {
                    final note = controller.buildNote();
                    context.push('/note/config', extra: note);
                  }
                : null,
            child: const Text('Suivant'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Titre du cours...',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.titleMedium,
              onChanged: controller.updateTitle,
            ),
            const Divider(),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Écris ta note ici...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: controller.updateContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
