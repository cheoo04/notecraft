// lib/features/note_editor/view/note_editor_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/audio_player_card.dart';
import '../../../services/storage_service.dart';
import '../controller/note_editor_controller.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  final List<String> _availableSubjects = [
    'Physique',
    'Biologie',
    'Économie',
    'Droit',
    'Informatique',
    'Maths',
    'Histoire',
    'Général',
  ];

  @override
  void initState() {
    super.initState();
    final initial = ref.read(noteEditorControllerProvider);
    _titleController = TextEditingController(text: initial.title)
      ..addListener(() {
        ref
            .read(noteEditorControllerProvider.notifier)
            .updateTitle(_titleController.text);
      });
    _contentController = TextEditingController(text: initial.content)
      ..addListener(() {
        ref
            .read(noteEditorControllerProvider.notifier)
            .updateContent(_contentController.text);
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onAddSketch() async {
    HapticFeedback.lightImpact();
    final path = await context.push<String>('/note/sketch');
    if (path != null) {
      ref.read(noteEditorControllerProvider.notifier).addSketch(path);
    }
  }

  Future<void> _onEditSketch(String existingPath) async {
    await context.push<String>('/note/sketch', extra: existingPath);
    if (!mounted) return;
    FileImage(File(existingPath)).evict();
    setState(() {});
  }

  void _onToggleAudio() {
    HapticFeedback.mediumImpact();
    final state = ref.read(noteEditorControllerProvider);
    final notifier = ref.read(noteEditorControllerProvider.notifier);

    if (state.isRecording) {
      notifier.stopRecording();
    } else {
      notifier.startRecording();
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajouter une photo de cours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.accentTeal),
                  title: const Text('Prendre en photo le tableau / slide'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.accentTeal),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        ref.read(noteEditorControllerProvider.notifier).addImage(picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'accéder à l\'image : $e')),
      );
    }
  }

  Future<void> _onNext() async {
    setState(() => _saving = true);
    final note = ref.read(noteEditorControllerProvider.notifier).buildNote();
    try {
      await ref.read(storageServiceProvider).saveNote(note);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    context.push('/note/config', extra: note);
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentSubject = ref.read(noteEditorControllerProvider).subject;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionner la matière',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableSubjects.map((subj) {
                    final selected = subj == currentSubject;
                    return ChoiceChip(
                      label: Text(subj),
                      selected: selected,
                      selectedColor: AppColors.accentTealLight,
                      labelStyle: TextStyle(
                        color:
                            selected ? AppColors.accentTeal : AppColors.inkDark,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        if (val) {
                          ref
                              .read(noteEditorControllerProvider.notifier)
                              .updateSubject(subj);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(noteEditorControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: _showSubjectPicker,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Matière du cours',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    editorState.subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.accentTeal),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer(
              builder: (context, ref, _) {
                final canProceed = ref.watch(
                  noteEditorControllerProvider.select((s) => s.canProceed),
                );
                return TextButton.icon(
                  onPressed: (canProceed && !_saving) ? _onNext : null,
                  label: const Text(
                    'Suivant',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, size: 16),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Titre du cours...',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black26,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.neutralBorder),
                  const SizedBox(height: 6),

                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText:
                          'Écris ta note ici (cours, concepts, formules)...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  // Carrousel des schémas dessinés
                  if (editorState.sketchPaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.draw_outlined,
                            size: 16, color: AppColors.accentTeal),
                        const SizedBox(width: 6),
                        Text(
                          'Schémas dessinés (${editorState.sketchPaths.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: editorState.sketchPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final path = editorState.sketchPaths[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => _onEditSketch(path),
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.neutralBorder),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(
                                          noteEditorControllerProvider.notifier)
                                      .removeSketch(path),
                                  child: const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: AppColors.inkDark,
                                    child: Icon(Icons.close,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  // Carrousel des photos de tableau
                  if (editorState.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined,
                            size: 16, color: AppColors.accentTeal),
                        const SizedBox(width: 6),
                        Text(
                          'Photos de tableau / slides (${editorState.imagePaths.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: editorState.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final path = editorState.imagePaths[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.neutralBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(
                                          noteEditorControllerProvider.notifier)
                                      .removeImage(path),
                                  child: const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: AppColors.inkDark,
                                    child: Icon(Icons.close,
                                        size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  // Carte Enregistrement / Lecteur Audio
                  if (editorState.isRecording) ...[
                    const SizedBox(height: 20),
                    _AudioRecordCard(
                      timerText: editorState.formattedRecordingTime,
                      onStop: () => ref
                          .read(noteEditorControllerProvider.notifier)
                          .stopRecording(),
                      onDelete: () => ref
                          .read(noteEditorControllerProvider.notifier)
                          .deleteAudio(),
                    ),
                  ] else if (editorState.audioPath != null) ...[
                    const SizedBox(height: 20),
                    AudioPlayerCard(
                      audioPath: editorState.audioPath!,
                      totalDuration: editorState.audioDuration,
                      onDelete: () => ref
                          .read(noteEditorControllerProvider.notifier)
                          .deleteAudio(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Barre d'outils basse
          _BottomCaptureBar(
            isRecording: editorState.isRecording,
            onSketchTap: _onAddSketch,
            onCameraTap: _showPhotoSourceSheet,
            onAudioTap: _onToggleAudio,
            onSubjectTap: _showSubjectPicker,
          ),
        ],
      ),
    );
  }
}

class _AudioRecordCard extends StatelessWidget {
  final String timerText;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  const _AudioRecordCard({
    required this.timerText,
    required this.onStop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: List.generate(
              5,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: i % 2 == 0 ? 16 : 24,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              timerText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            onPressed: onStop,
            tooltip: 'Arrêter l\'enregistrement',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textMuted, size: 20),
            onPressed: onDelete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}

class _BottomCaptureBar extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onSketchTap;
  final VoidCallback onCameraTap;
  final VoidCallback onAudioTap;
  final VoidCallback onSubjectTap;

  const _BottomCaptureBar({
    required this.isRecording,
    required this.onSketchTap,
    required this.onCameraTap,
    required this.onAudioTap,
    required this.onSubjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.neutralBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 10,
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.draw_outlined),
            color: AppColors.inkDark,
            tooltip: 'Dessiner un schéma',
            onPressed: onSketchTap,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            color: AppColors.accentTeal,
            tooltip: 'Photo de tableau / slide',
            onPressed: onCameraTap,
          ),
          Container(
            decoration: BoxDecoration(
              color:
                  isRecording ? Colors.redAccent.withValues(alpha: 0.1) : null,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isRecording ? Icons.mic : Icons.mic_none_outlined,
                color: isRecording ? Colors.redAccent : AppColors.inkDark,
              ),
              tooltip: isRecording
                  ? 'Arrêter l\'enregistrement'
                  : 'Enregistrer (≤ 30 min)',
              onPressed: onAudioTap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.label_outline),
            color: AppColors.inkDark,
            tooltip: 'Changer la matière',
            onPressed: onSubjectTap,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            color: AppColors.textMuted,
            tooltip: 'Annuler',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
