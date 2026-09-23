// lib/features/home/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../models/note.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final userProfile =
        ref.watch(settingsControllerProvider.select((s) => s.profile));

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentTeal,
          onRefresh: () async {
            await controller.loadNotes();
            await ref
                .read(settingsControllerProvider.notifier)
                .refreshQuotaUsage();
          },
          child: CustomScrollView(
            slivers: [
              // En-tete dynamique : Vrai Prenom + Vraies Initiales
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${userProfile.firstName}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mes Notes & Synthèses',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accentTealLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.accentTeal.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            userProfile.initials.isNotEmpty
                                ? userProfile.initials
                                : 'NC',
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Barre de recherche universelle
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neutralBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      onChanged: controller.updateSearch,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                        hintText: 'Rechercher cours, formule, idée...',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              // Filtres rapides horizontaux
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isSelected:
                            homeState.selectedFilter == NoteFilterType.tous,
                        onTap: () =>
                            controller.selectFilter(NoteFilterType.tous),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Cornell',
                        isSelected:
                            homeState.selectedFilter == NoteFilterType.cornell,
                        onTap: () =>
                            controller.selectFilter(NoteFilterType.cornell),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Audio',
                        isSelected:
                            homeState.selectedFilter == NoteFilterType.audio,
                        onTap: () =>
                            controller.selectFilter(NoteFilterType.audio),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Fiches',
                        isSelected:
                            homeState.selectedFilter == NoteFilterType.fiches,
                        onTap: () =>
                            controller.selectFilter(NoteFilterType.fiches),
                      ),
                    ],
                  ),
                ),
              ),

              // Banniere Capture Rapide
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF134E4A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.inkDark.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CAPTURE RAPIDE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Capturer une idée ou un cours',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Texte, schémas ou enregistrement audio',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.accentTeal,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => context.push('/note/new'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Créer une note',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Titre section "Dernieres captures"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Text(
                    'Dernières captures',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),

              // Liste des notes récentes
              if (homeState.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.accentTeal),
                    ),
                  ),
                )
              else if (homeState.filteredNotes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            homeState.searchQuery.isNotEmpty
                                ? 'Aucun résultat pour cette recherche'
                                : 'Aucune note pour le moment',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = homeState.filteredNotes[index];
                        return _NoteCard(
                          note: note,
                          onTap: () =>
                              context.push('/note/detail', extra: note),
                        );
                      },
                      childCount: homeState.filteredNotes.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentTeal : AppColors.neutralBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.inkDark,
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<String> details = [];
    if (note.subject.isNotEmpty && note.subject != 'Général') {
      details.add(note.subject);
    }
    if (note.audioPath != null) {
      final min = note.audioDuration?.inMinutes ?? 0;
      details.add('Audio ${min > 0 ? "$min min" : ""}');
    }
    if (note.rawSketchPaths.isNotEmpty) {
      details.add('${note.rawSketchPaths.length} schéma(s)');
    }
    details.add(formatNoteDate(note.createdAt));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.neutralBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentTealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              note.rawSketchPaths.isNotEmpty
                  ? Icons.draw_outlined
                  : (note.audioPath != null
                      ? Icons.mic_none_rounded
                      : Icons.description_outlined),
              color: AppColors.accentTeal,
              size: 20,
            ),
          ),
          title: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.inkDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              details.join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
