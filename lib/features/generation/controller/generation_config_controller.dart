// lib/features/generation/controller/generation_config_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';

class FormatMeta {
  final String label;
  final String subtitle;
  final IconData icon;

  const FormatMeta({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class GenerationConfigState {
  final DocumentFormat format;
  final GenerationMode mode;

  const GenerationConfigState({
    this.format = DocumentFormat.resume,
    this.mode = GenerationMode.express,
  });

  GenerationConfigState copyWith({
    DocumentFormat? format,
    GenerationMode? mode,
  }) {
    return GenerationConfigState(
      format: format ?? this.format,
      mode: mode ?? this.mode,
    );
  }
}

class GenerationConfigController extends Notifier<GenerationConfigState> {
  @override
  GenerationConfigState build() => const GenerationConfigState();

  void selectFormat(DocumentFormat format) {
    state = state.copyWith(format: format);
  }

  void selectMode(GenerationMode mode) {
    state = state.copyWith(mode: mode);
  }
}

final generationConfigControllerProvider =
    NotifierProvider<GenerationConfigController, GenerationConfigState>(
  GenerationConfigController.new,
);

FormatMeta getFormatMeta(DocumentFormat format) {
  switch (format) {
    case DocumentFormat.resume:
      return const FormatMeta(
        label: 'Résumé Structuré',
        subtitle: 'Synthèse condensée',
        icon: Icons.article_outlined,
      );
    case DocumentFormat.ficheDeRevision:
      return const FormatMeta(
        label: 'Fiche Révision',
        subtitle: 'Méthode Cornell & Q/R',
        icon: Icons.school_outlined,
      );
    case DocumentFormat.flashcards:
      return const FormatMeta(
        label: 'Flashcards & Quiz',
        subtitle: 'Cartes mémo interactives',
        icon: Icons.style_outlined,
      );
    case DocumentFormat.planDeCours:
      return const FormatMeta(
        label: 'Plan de Cours',
        subtitle: 'Grandes parties I, II, III',
        icon: Icons.format_list_bulleted_rounded,
      );
    case DocumentFormat.rapport:
      return const FormatMeta(
        label: 'Rapport Détaillé',
        subtitle: 'Analyse exhaustive',
        icon: Icons.menu_book_outlined,
      );
    case DocumentFormat.expose:
      return const FormatMeta(
        label: 'Exposé Oral',
        subtitle: 'Plan & argumentation',
        icon: Icons.record_voice_over_outlined,
      );
  }
}

String formatLabel(DocumentFormat format) => getFormatMeta(format).label;
