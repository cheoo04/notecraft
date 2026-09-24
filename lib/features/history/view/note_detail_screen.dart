// lib/features/history/view/note_detail_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../core/widgets/audio_player_card.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../../../services/storage_service.dart';
import '../../generation/controller/generation_config_controller.dart';
import '../../home/controller/home_controller.dart';

class NoteDetailScreen extends ConsumerWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  Color _getBadgeBg(String subject) {
    switch (subject.toLowerCase()) {
      case 'physique':
        return AppColors.badgePhysiqueBg;
      case 'économie':
      case 'eco':
      case 'éco':
        return AppColors.badgeEcoBg;
      case 'droit':
        return AppColors.badgeDroitBg;
      default:
        return AppColors.accentTealLight;
    }
  }

  Color _getBadgeText(String subject) {
    switch (subject.toLowerCase()) {
      case 'physique':
        return AppColors.badgePhysiqueText;
      case 'économie':
      case 'eco':
      case 'éco':
        return AppColors.badgeEcoText;
      case 'droit':
        return AppColors.badgeDroitText;
      default:
        return AppColors.accentTeal;
    }
  }

  Future<void> _confirmDeleteNote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer cette note ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          'Cette action supprimera le cours ainsi que tous les documents générés rattachés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(storageServiceProvider).deleteNote(note.id);
      await ref.read(homeControllerProvider.notifier).loadNotes();
      if (!context.mounted) return;
      context.pop();
    }
  }

  Future<void> _deleteDocument(WidgetRef ref, String docId) async {
    HapticFeedback.lightImpact();
    await ref.read(storageServiceProvider).deleteDocument(docId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsStreamProvider(note.id));

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: const Text('Détail de la note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Supprimer cette note',
            onPressed: () => _confirmDeleteNote(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Carte Brouillon Source
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.neutralBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getBadgeBg(note.subject),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.subject.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getBadgeText(note.subject),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            formatNoteDate(note.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (note.rawText != null &&
                          note.rawText!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.canvasGrey,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.neutralBorder),
                          ),
                          child: Text(
                            note.rawText!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      if (note.rawSketchPaths.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.draw_outlined,
                              size: 16,
                              color: AppColors.accentTeal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${note.rawSketchPaths.length} schéma(s) rattaché(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: note.rawSketchPaths.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final path = note.rawSketchPaths[index];
                              return Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.neutralBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Lecteur Audio interactif dans la note
                      if (note.audioPath != null) ...[
                        const SizedBox(height: 16),
                        AudioPlayerCard(
                          audioPath: note.audioPath!,
                          totalDuration: note.audioDuration,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Section Documents generes
              Text(
                'Documents générés',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),

              docsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        CircularProgressIndicator(color: AppColors.accentTeal),
                  ),
                ),
                error: (err, _) => Center(child: Text('Erreur : $err')),
                data: (documents) {
                  if (documents.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Aucun document généré pour cette note',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: documents.map((doc) {
                      final meta = getFormatMeta(doc.format);
                      final isExpress = doc.mode == GenerationMode.express;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: AppColors.neutralBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.accentTealLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                meta.icon,
                                color: AppColors.accentTeal,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              meta.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkDark,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpress
                                          ? AppColors.neutralFill
                                          : AppColors.accentTealLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isExpress ? 'Express' : 'Affiné',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isExpress
                                            ? AppColors.textMuted
                                            : AppColors.accentTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatNoteDate(doc.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.grey),
                                  tooltip: 'Supprimer ce document',
                                  onPressed: () => _deleteDocument(ref, doc.id),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.push('/document/${doc.id}', extra: doc);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'Nouveau format',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/note/config', extra: note);
        },
      ),
    );
  }
}
