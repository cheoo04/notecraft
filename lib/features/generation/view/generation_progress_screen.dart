// lib/features/generation/view/generation_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../controller/generation_pipeline_controller.dart';
import '../generation_request_args.dart';

class GenerationProgressScreen extends ConsumerStatefulWidget {
  final GenerationRequestArgs? args;

  const GenerationProgressScreen({super.key, this.args});

  @override
  ConsumerState<GenerationProgressScreen> createState() =>
      _GenerationProgressScreenState();
}

class _GenerationProgressScreenState
    extends ConsumerState<GenerationProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pipeline = ref.read(generationPipelineControllerProvider);
      // Demarre la generation seulement si elle n'est pas deja en cours
      if (!pipeline.isRunning && widget.args != null) {
        ref
            .read(generationPipelineControllerProvider.notifier)
            .runPipeline(widget.args!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      return const Scaffold(body: Center(child: Text('Aucune requête reçue')));
    }

    final pipelineState = ref.watch(generationPipelineControllerProvider);
    final isAffine = widget.args!.mode == GenerationMode.affine;

    // Redirection automatique des que le document est pret
    ref.listen(generationPipelineControllerProvider, (previous, next) {
      if (next.currentStep == PipelineStep.completed &&
          next.resultDocument != null) {
        context.replace(
          '/document/${next.resultDocument!.id}',
          extra: next.resultDocument,
        );
      }
    });

    final hasAudio = widget.args!.note.audioPaths.isNotEmpty;
    final hasSketch = widget.args!.note.rawSketchPaths.isNotEmpty;
    final hasImages = widget.args!.note.imagePaths.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pipelineState.error == null) ...[
                  // Jauge circulaire avec pourcentage
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: pipelineState.percentage / 100.0,
                          strokeWidth: 8,
                          backgroundColor: AppColors.neutralBorder,
                          color: AppColors.accentTeal,
                        ),
                      ),
                      Text(
                        '${pipelineState.percentage}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    isAffine
                        ? 'Analyse Affinée en cours...'
                        : 'Génération Express en cours...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nettoyage des schémas, analyse vocale & structuration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Liste d'etapes animees
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neutralBorder),
                    ),
                    child: Column(
                      children: [
                        _ProgressStepItem(
                          label: hasImages
                              ? 'Texte brut & photos de tableau analysés'
                              : 'Traitement du texte brut',
                          isDone: pipelineState.percentage >= 30,
                          isInProgress: pipelineState.percentage < 30,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: hasAudio
                              ? 'Enregistrements vocaux analysés (${widget.args!.note.audioPaths.length})'
                              : 'Contenu audio vérifié',
                          isDone: pipelineState.percentage >= 65,
                          isInProgress:
                              pipelineState.currentStep == PipelineStep.audio,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: hasSketch
                              ? 'Vectorisation des schémas joints'
                              : 'Vérification des éléments graphiques',
                          isDone: pipelineState.percentage >= 85,
                          isInProgress:
                              pipelineState.currentStep == PipelineStep.sketch,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: 'Rédaction et mise en page finale',
                          isDone: pipelineState.percentage == 100,
                          isInProgress:
                              pipelineState.currentStep == PipelineStep.layout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // VRAI BOUTON ARRIERE-PLAN FONCTIONNEL
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back,
                        size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Génération en cours en arrière-plan. Le document apparaîtra dans votre historique dès qu\'il sera prêt.',
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    label: const Text(
                      'Passer en arrière-plan',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur : ${pipelineState.error}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(generationPipelineControllerProvider.notifier)
                          .runPipeline(widget.args!);
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStepItem extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isInProgress;

  const _ProgressStepItem({
    required this.label,
    required this.isDone,
    required this.isInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isDone)
          const Icon(Icons.check_circle, color: AppColors.accentTeal, size: 20)
        else if (isInProgress)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accentTeal,
            ),
          )
        else
          Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isInProgress ? FontWeight.w700 : FontWeight.w500,
              color: isDone || isInProgress
                  ? AppColors.inkDark
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
