// lib/features/history/view/note_detail_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../../../services/storage_service.dart';
import '../../generation/controller/generation_config_controller.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: const Text('Détail de la note'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Carte "Brouillon Source"
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
                      // Badge Matière + Date
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

                      // Titre du cours
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Contenu brut
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

                      // Aperçu des schémas attachés
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

                      // Badge Audio si présent
                      if (note.audioPath != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutralFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mic_none_rounded,
                                size: 16,
                                color: AppColors.accentTeal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Audio capturé (${note.audioDuration?.inMinutes ?? 0} min)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. En-tête Section "Documents générés"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documents générés',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Liste des documents générés
              FutureBuilder<List<GeneratedDocument>>(
                future: ref
                    .read(storageServiceProvider)
                    .getDocumentsForNote(note.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final documents = snapshot.data ?? const [];

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
                          const SizedBox(height: 4),
                          const Text(
                            'Choisis un format pour créer ta première fiche de révision, résumé ou rapport.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isExpress
                                              ? Icons.bolt
                                              : Icons.auto_awesome,
                                          size: 12,
                                          color: isExpress
                                              ? AppColors.textMuted
                                              : AppColors.accentTeal,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isExpress ? 'Express' : 'Affiné',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isExpress
                                                ? AppColors.textMuted
                                                : AppColors.accentTeal,
                                          ),
                                        ),
                                      ],
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
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                              size: 20,
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
