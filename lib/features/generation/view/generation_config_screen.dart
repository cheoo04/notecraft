import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../models/note.dart';
import '../controller/generation_config_controller.dart';
import '../generation_request_args.dart';

/// Écran 3 — Configuration du format & du mode.
class GenerationConfigScreen extends ConsumerWidget {
  final Note? note;

  const GenerationConfigScreen({super.key, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationConfigControllerProvider);
    final controller = ref.read(generationConfigControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: note == null
          ? const Center(child: Text('Aucune note reçue'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '1. Format de sortie souhaité',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: DocumentFormat.values.map((format) {
                      final selected = state.format == format;
                      return _FormatCard(
                        label: formatLabel(format),
                        selected: selected,
                        onTap: () => controller.selectFormat(format),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '2. Mode de traitement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ModeSelector(
                    mode: state.mode,
                    onChanged: controller.selectMode,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      context.push(
                        '/note/progress',
                        extra: GenerationRequestArgs(
                          note: note!,
                          format: state.format,
                          mode: state.mode,
                        ),
                      );
                    },
                    child: const Text('Lancer la génération'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.accentTeal.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: selected ? AppColors.accentTeal : AppColors.neutralBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.accentTeal : AppColors.inkDark,
          ),
        ),
      ),
    );
  }
}

/// Sélecteur Express / Affiné.
/// Distinction uniquement par teal (sélectionné) vs gris neutre : pas de
/// jaune/or, conformément à la correction validée dans le cahier des charges.
class _ModeSelector extends StatelessWidget {
  final GenerationMode mode;
  final ValueChanged<GenerationMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeOption(
            label: 'Express',
            sublabel: '~10 s',
            selected: mode == GenerationMode.express,
            onTap: () => onChanged(GenerationMode.express),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeOption(
            label: 'Affiné',
            sublabel: 'quelques min',
            selected: mode == GenerationMode.affine,
            onTap: () => onChanged(GenerationMode.affine),
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentTeal.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: selected ? AppColors.accentTeal : AppColors.neutralBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.accentTeal : AppColors.inkDark,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.accentTeal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
