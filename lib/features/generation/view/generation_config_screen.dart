// lib/features/generation/view/generation_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../controller/generation_config_controller.dart';
import '../generation_request_args.dart';

class GenerationConfigScreen extends ConsumerWidget {
  final Note? note;

  const GenerationConfigScreen({super.key, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationConfigControllerProvider);
    final controller = ref.read(generationConfigControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Configuration'),
      ),
      body: note == null
          ? const Center(child: Text('Aucune note reçue'))
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '1. Format de sortie souhaité',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Grille des formats avec icônes et sous-titres
                    Expanded(
                      child: ListView(
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: DocumentFormat.values.map((format) {
                              final meta = getFormatMeta(format);
                              final selected = state.format == format;
                              return _FormatCard(
                                meta: meta,
                                selected: selected,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  controller.selectFormat(format);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            '2. Mode de traitement',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Sélecteur Express vs Affiné
                          _ModeSegmentedControl(
                            mode: state.mode,
                            onChanged: (newMode) {
                              HapticFeedback.selectionClick();
                              controller.selectMode(newMode);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Encart descriptif du mode sélectionné (sans jaune)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentTealLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.accentTeal.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.accentTeal,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.mode == GenerationMode.express
                                            ? 'Mode Express sélectionné'
                                            : 'Mode Affiné sélectionné',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentTeal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        state.mode == GenerationMode.express
                                            ? 'Génération quasi-instantanée en 10 secondes. Idéal pour les synthèses textuelles directes.'
                                            : 'Analyse approfondie (1-2 min). Vectorise proprement les croquis et retranscrit l\'audio jusqu\'à 30 min.',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkDark,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bouton de validation
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(
                          '/note/progress',
                          extra: GenerationRequestArgs(
                            note: note!,
                            format: state.format,
                            mode: state.mode,
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lancer la génération',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final FormatMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentTealLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.accentTeal : AppColors.neutralBorder,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                meta.icon,
                color: selected ? AppColors.accentTeal : AppColors.inkDark,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                meta.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.accentTeal : AppColors.inkDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.accentTeal : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSegmentedControl extends StatelessWidget {
  final GenerationMode mode;
  final ValueChanged<GenerationMode> onChanged;

  const _ModeSegmentedControl({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutralFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              title: 'Express',
              subtitle: '~10 s',
              icon: Icons.bolt,
              isSelected: mode == GenerationMode.express,
              onTap: () => onChanged(GenerationMode.express),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeButton(
              title: 'Affiné',
              subtitle: '1-2 min',
              icon: Icons.auto_awesome,
              isSelected: mode == GenerationMode.affine,
              onTap: () => onChanged(GenerationMode.affine),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color:
                      isSelected ? AppColors.accentTeal : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.accentTeal : AppColors.inkDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.accentTeal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
