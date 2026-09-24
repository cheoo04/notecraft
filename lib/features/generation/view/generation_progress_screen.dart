// lib/features/generation/view/generation_progress_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../services/ai_service.dart';
import '../../../services/sketch_service.dart';
import '../../../services/storage_service.dart';
import '../generation_request_args.dart';

enum StepStatus { pending, inProgress, completed }

class GenerationProgressScreen extends ConsumerStatefulWidget {
  final GenerationRequestArgs? args;

  const GenerationProgressScreen({super.key, this.args});

  @override
  ConsumerState<GenerationProgressScreen> createState() =>
      _GenerationProgressScreenState();
}

class _GenerationProgressScreenState
    extends ConsumerState<GenerationProgressScreen> {
  String? _error;
  int _percentage = 15;

  StepStatus _textStep = StepStatus.inProgress;
  StepStatus _audioStep = StepStatus.pending;
  StepStatus _sketchStep = StepStatus.pending;
  StepStatus _layoutStep = StepStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _executePipeline());
  }

  Future<void> _executePipeline() async {
    final args = widget.args;
    if (args == null) return;

    try {
      var note = args.note;
      final svgPaths = <String>[];

      // Etape 1 : Analyse du texte brut
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _textStep = StepStatus.completed;
        _percentage = 35;
      });

      // Etape 2 : Retranscription audio si present
      if (note.audioPath != null) {
        setState(() => _audioStep = StepStatus.inProgress);
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          _audioStep = StepStatus.completed;
          _percentage = 50;
        });
      }

      // Etape 3 : Vectorisation des schemas
      if (note.rawSketchPaths.isNotEmpty) {
        setState(() => _sketchStep = StepStatus.inProgress);
        final sketchService = ref.read(sketchServiceProvider);
        final descriptions = <String>[];

        for (final path in note.rawSketchPaths) {
          try {
            final result = await sketchService.vectorize(path);
            svgPaths.add(result.svgPath);
            descriptions.add(result.description);
          } catch (_) {}
        }

        if (descriptions.isNotEmpty) {
          final schemaSection =
              '--- Schémas fournis avec la note ---\n${descriptions.join('\n\n')}';
          note = note.copyWith(
            rawText: '${note.rawText ?? ''}\n\n$schemaSection',
          );
        }

        setState(() {
          _sketchStep = StepStatus.completed;
          _percentage = 70;
        });
      }

      // Etape 4 : Redaction et mise en page IA
      setState(() => _layoutStep = StepStatus.inProgress);
      final aiService = ref.read(aiServiceProvider);
      var document = await aiService.generate(
        note: note,
        format: args.format,
        mode: args.mode,
      );

      if (svgPaths.isNotEmpty) {
        document = document.copyWith(cleanedSketchSvgPaths: svgPaths);
      }

      setState(() {
        _layoutStep = StepStatus.completed;
        _percentage = 100;
      });

      try {
        await ref.read(storageServiceProvider).saveDocument(document);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.replace('/document/${document.id}', extra: document);
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      // Extraction propre du message d'erreur du backend
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        }
      }
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      return const Scaffold(body: Center(child: Text('Aucune requête reçue')));
    }

    final isAffine = widget.args!.mode == GenerationMode.affine;

    return Scaffold(
      backgroundColor: AppColors.canvasGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error == null) ...[
                  // Jauge circulaire avec pourcentage
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _percentage / 100.0,
                          strokeWidth: 8,
                          backgroundColor: AppColors.neutralBorder,
                          color: AppColors.accentTeal,
                        ),
                      ),
                      Text(
                        '$_percentage%',
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
                    'Nettoyage des schémas & structuration du document',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Liste d'étapes validées pas à pas
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
                          label: 'Traitement du texte brut',
                          status: _textStep,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: widget.args!.note.audioPath != null
                              ? 'Enregistrement vocal analysé'
                              : 'Contenu audio vérifié',
                          status: _audioStep,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: widget.args!.note.rawSketchPaths.isNotEmpty
                              ? 'Vectorisation des schémas joints'
                              : 'Vérification des éléments graphiques',
                          status: _sketchStep,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: 'Rédaction et mise en page finale',
                          status: _layoutStep,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
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
                    'Erreur : $_error',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _percentage = 15;
                        _textStep = StepStatus.inProgress;
                        _audioStep = StepStatus.pending;
                        _sketchStep = StepStatus.pending;
                        _layoutStep = StepStatus.pending;
                      });
                      _executePipeline();
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
  final StepStatus status;

  const _ProgressStepItem({
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (status == StepStatus.completed)
          const Icon(Icons.check_circle, color: AppColors.accentTeal, size: 20)
        else if (status == StepStatus.inProgress)
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
              fontWeight: status == StepStatus.inProgress
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: status == StepStatus.pending
                  ? AppColors.textMuted
                  : AppColors.inkDark,
            ),
          ),
        ),
      ],
    );
  }
}
