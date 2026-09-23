// lib/features/settings/view/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../models/user_preferences.dart';
import '../../generation/controller/generation_config_controller.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showTonePicker(
      BuildContext context, WidgetRef ref, WritingTone current) {
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
                  'Choisir le ton par défaut',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Académique & Synthétique'),
                  subtitle: const Text(
                      'Rigoureux et précis, idéal pour l\'université'),
                  trailing: current == WritingTone.academique
                      ? const Icon(Icons.check, color: AppColors.accentTeal)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateTone(WritingTone.academique);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Professionnel'),
                  subtitle: const Text('Direct et orienté livrable de réunion'),
                  trailing: current == WritingTone.professionnel
                      ? const Icon(Icons.check, color: AppColors.accentTeal)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateTone(WritingTone.professionnel);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Décontracté & Vulgarisé'),
                  subtitle: const Text(
                      'Style accessible pour une compréhension rapide'),
                  trailing: current == WritingTone.decontracte
                      ? const Icon(Icons.check, color: AppColors.accentTeal)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateTone(WritingTone.decontracte);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormatPicker(
      BuildContext context, WidgetRef ref, DocumentFormat current) {
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
                  'Format favori par défaut',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                const SizedBox(height: 12),
                for (final f in DocumentFormat.values)
                  ListTile(
                    title: Text(formatLabel(f)),
                    trailing: current == f
                        ? const Icon(Icons.check, color: AppColors.accentTeal)
                        : null,
                    onTap: () {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateFormat(f);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Carte de profil (Diapositive 9)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentTealLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentTeal.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AM',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alex Martin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentTealLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Abonnement Étudiant Pro',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Préférences de génération
            const _SectionHeader(title: 'PRÉFÉRENCES DE GÉNÉRATION'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Ton par défaut',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      settings.tone == WritingTone.academique
                          ? 'Académique & Synthétique'
                          : (settings.tone == WritingTone.professionnel
                              ? 'Professionnel'
                              : 'Décontracté'),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showTonePicker(context, ref, settings.tone),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Format favori',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      formatLabel(settings.format),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () =>
                        _showFormatPicker(context, ref, settings.format),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Conserver les fichiers audio',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Sauvegarder les 30 min brutes localement',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    activeThumbColor: AppColors.accentTeal,
                    value: settings.keepAudioFiles,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      controller.toggleKeepAudio(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Abonnement & Quota
            const _SectionHeader(title: 'ABONNEMENT & QUOTA'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Traitements Affinés',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkDark,
                        ),
                      ),
                      Text(
                        '${settings.affineUsed} / ${settings.affineTotal} ce mois',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: settings.affineUsed / settings.affineTotal,
                      minHeight: 8,
                      backgroundColor: AppColors.neutralFill,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Conformité & Stockage
            const _SectionHeader(title: 'CONFORMITÉ & STOCKAGE'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.accentTeal,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chiffrement local des données audio et respect des règles de confidentialité pour les notes personnelles de cours.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}
