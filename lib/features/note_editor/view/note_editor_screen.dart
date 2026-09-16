import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/note_editor_controller.dart';

/// Écran 2 — Page blanche (V1 : saisie texte uniquement).
/// Esquisse, image et audio seront ajoutés dans une itération suivante,
/// une fois ce flux de base validé.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(noteEditorControllerProvider);
    _titleController = TextEditingController(text: initial.title)
      ..addListener(() {
        ref.read(noteEditorControllerProvider.notifier).updateTitle(_titleController.text);
      });
    _contentController = TextEditingController(text: initial.content)
      ..addListener(() {
        ref.read(noteEditorControllerProvider.notifier).updateContent(_contentController.text);
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle note'),
        actions: [
          // Seul ce bouton écoute le provider — les TextField ne rebuild
          // plus jamais pendant la frappe, ce qui évite d'interrompre la
          // composition IME des caractères accentués.
          Consumer(
            builder: (context, ref, _) {
              final canProceed = ref.watch(
                noteEditorControllerProvider.select((s) => s.canProceed),
              );
              return TextButton(
                onPressed: canProceed
                    ? () {
                        final note =
                            ref.read(noteEditorControllerProvider.notifier).buildNote();
                        context.push('/note/config', extra: note);
                      }
                    : null,
                child: const Text('Suivant'),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Titre du cours...',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Écris ta note ici...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
