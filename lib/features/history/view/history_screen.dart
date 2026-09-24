// lib/features/history/view/history_screen.dart

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

  void _showRegeneratePicker(BuildContext context, List<Note> notes) {
    HapticFeedback.mediumImpact();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune note disponible à régénérer')),
      );
      return;
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisir une note à régénérer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sélectionne le cours à décliner sous un autre format',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = notes[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _getBadgeBg(n.subject),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: _getBadgeText(n.subject),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkDark,
                          ),
                        ),
                        subtitle: Text(
                          '${n.subject} • ${formatNoteDate(n.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/note/config', extra: n);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: const Text('Historique des Notes'),
      ),
      body: SafeArea(
        child: notesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentTeal),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur de chargement : $err'),
            ),
          ),
          data: (allNotes) {
            if (allNotes.isEmpty) {
              return const Center(child: Text('Aucune note enregistrée'));
            }

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
                Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => _showRegeneratePicker(context, allNotes),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
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
                                  'Appuie pour décliner un cours en Fiche, Exposé ou Rapport',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.accentTeal,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
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
    final docsAsync = ref.watch(documentsStreamProvider(note.id));

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
                docsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (docs) {
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
