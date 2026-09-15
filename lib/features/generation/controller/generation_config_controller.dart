import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';

class GenerationConfigState {
  final DocumentFormat format;
  final GenerationMode mode;

  const GenerationConfigState({
    this.format = DocumentFormat.ficheDeRevision,
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

/// Libellés affichés pour chaque format (utilisés par l'écran et les tests).
String formatLabel(DocumentFormat format) {
  switch (format) {
    case DocumentFormat.resume:
      return 'Résumé';
    case DocumentFormat.rapport:
      return 'Rapport';
    case DocumentFormat.expose:
      return 'Exposé';
    case DocumentFormat.planDeCours:
      return 'Plan de cours';
    case DocumentFormat.ficheDeRevision:
      return 'Fiche de révision';
  }
}
