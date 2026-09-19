import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/storage_service.dart';
import '../controller/note_editor_controller.dart';

/// Écran 2 — Page blanche (V1 : texte + esquisses).
/// Image et audio seront ajoutés dans une itération suivante.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

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

  Future<void> _onAddSketch() async {
    final path = await context.push<String>('/note/sketch');
    if (path != null) {
      ref.read(noteEditorControllerProvider.notifier).addSketch(path);
    }
  }

  Future<void> _onEditSketch(String existingPath) async {
    await context.push<String>('/note/sketch', extra: existingPath);
    if (!mounted) return;
    // Le fichier a été réécrit au même chemin : on invalide le cache
    // d'image de Flutter (indexé par chemin, pas par contenu) pour que
    // la miniature reflète bien la dernière version.
    FileImage(File(existingPath)).evict();
    setState(() {});
  }

  void _onRemoveSketch(String path) {
    ref.read(noteEditorControllerProvider.notifier).removeSketch(path);
  }

  Future<void> _onNext() async {
    setState(() => _saving = true);
    final note = ref.read(noteEditorControllerProvider.notifier).buildNote();
    try {
      await ref.read(storageServiceProvider).saveNote(note);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note non sauvegardée (hors-ligne ?) : $e')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    context.push('/note/config', extra: note);
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
                onPressed: (canProceed && !_saving) ? _onNext : null,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Suivant'),
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
            const Divider(),
            Text('Schémas', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final sketchPaths = ref.watch(
                  noteEditorControllerProvider.select((s) => s.sketchPaths),
                );
                return SizedBox(
                  height: 72,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final path in sketchPaths)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _onEditSketch(path),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey.shade100,
                                    child: Image.file(
                                      File(path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => _onRemoveSketch(path),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _onAddSketch,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
