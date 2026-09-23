// lib/features/history/view/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../../../services/storage_service.dart';
import '../../generation/controller/generation_config_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedSubject = 'Toutes';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: const Text('Historique des Notes'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Note>>(
          future: ref.read(storageServiceProvider).getNotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accentTeal),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur de chargement : ${snapshot.error}'),
                ),
              );
            }

            final allNotes = snapshot.data ?? const [];
            if (allNotes.isEmpty) {
              return const Center(child: Text('Aucune note enregistrée'));
            }

            // Extraction des matières uniques
            final subjects = <String>{'Toutes'};
            for (final n in allNotes) {
              if (n.subject.isNotEmpty && n.subject != 'Général') {
                subjects.add(n.subject);
              }
            }

            final filteredNotes = _selectedSubject == 'Toutes'
                ? allNotes
                : allNotes.where((n) => n.subject == _selectedSubject).toList();

            return Column(
              children: [
                // Filtre par matière (Pills horizontales)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: subjects.map((subj) {
                      final isSelected = _selectedSubject == subj;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSubject = subj),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentTeal
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentTeal
                                    : AppColors.neutralBorder,
                              ),
                            ),
                            child: Text(
                              subj,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.inkDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Liste des cartes d'historique
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return _HistoryNoteCard(
                        note: note,
                        badgeBg: _getBadgeBg(note.subject),
                        badgeText: _getBadgeText(note.subject),
                        onTap: () => context.push('/note/detail', extra: note),
                      );
                    },
                  ),
                ),

                // Bannière basse de régénération (Slide 8)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.neutralBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentTealLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.accentTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Régénérer dans un autre format',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkDark,
                              ),
                            ),
                            Text(
                              'Transformez vos notes existantes en Exposé ou Rapport',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryNoteCard extends ConsumerWidget {
  final Note note;
  final Color badgeBg;
  final Color badgeText;
  final VoidCallback onTap;

  const _HistoryNoteCard({
    required this.note,
    required this.badgeBg,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.neutralBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.subject.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
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
                const SizedBox(height: 10),
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Chargement des documents associés pour afficher les badges
                FutureBuilder<List<GeneratedDocument>>(
                  future: ref
                      .read(storageServiceProvider)
                      .getDocumentsForNote(note.id),
                  builder: (context, snapshot) {
                    final docs = snapshot.data ?? const [];
                    if (docs.isEmpty) {
                      return const Text(
                        'Aucun document généré',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted),
                      );
                    }
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: docs.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neutralFill,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.neutralBorder),
                          ),
                          child: Text(
                            formatLabel(d.format),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkDark,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
