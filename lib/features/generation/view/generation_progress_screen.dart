// lib/features/generation/view/generation_progress_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../services/ai_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/sketch_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/transcription_service.dart';
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
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _textStep = StepStatus.completed;
        _percentage = 25;
      });

      // Etape 1b : Extraction Vision OCR sur photos de tableau si presentes
      if (note.imagePaths.isNotEmpty) {
        final ocrService = ref.read(ocrServiceProvider);
        final ocrResults = <String>[];
        for (final imgPath in note.imagePaths) {
          try {
            final extracted = await ocrService.extractTextFromImage(imgPath);
            if (extracted.trim().isNotEmpty) {
              ocrResults.add(extracted.trim());
            }
          } catch (_) {}
        }
        if (ocrResults.isNotEmpty) {
          final ocrSection =
              '--- Contenu extrait des photos de tableau et diapositives ---\n${ocrResults.join('\n\n')}';
          note = note.copyWith(
            rawText: '${note.rawText ?? ''}\n\n$ocrSection',
          );
        }
      }

      // Etape 2 : Retranscription de tous les extraits audio Whisper dans l'ordre
      if (note.audioPaths.isNotEmpty) {
        setState(() => _audioStep = StepStatus.inProgress);
        final transcriptionService = ref.read(transcriptionServiceProvider);
        final audioTexts = <String>[];

        for (int i = 0; i < note.audioPaths.length; i++) {
          try {
            final text =
                await transcriptionService.transcribe(note.audioPaths[i]);
            if (text.trim().isNotEmpty) {
              audioTexts.add('Extrait ${i + 1} :\n$text');
            }
          } catch (_) {}
        }

        if (audioTexts.isNotEmpty) {
          final audioSection =
              '--- Retranscription des enregistrements oraux du cours ---\n${audioTexts.join('\n\n')}';
          note = note.copyWith(
            rawText: '${note.rawText ?? ''}\n\n$audioSection',
          );
        }

        setState(() {
          _audioStep = StepStatus.completed;
          _percentage = 55;
        });
      }

      // Etape 3 : Vectorisation des schemas joints
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
          _percentage = 75;
        });
      }

      // Etape 4 : Redaction et mise en page finale
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
                    'Nettoyage des schémas, analyse OCR & structuration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                          label: widget.args!.note.imagePaths.isNotEmpty
                              ? 'Texte brut & photos de tableau analysés'
                              : 'Traitement du texte brut',
                          status: _textStep,
                        ),
                        const Divider(height: 18),
                        _ProgressStepItem(
                          label: widget.args!.note.audioPaths.isNotEmpty
                              ? 'Enregistrements vocaux analysés (${widget.args!.note.audioPaths.length})'
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
