// lib/features/generation/controller/generation_pipeline_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';
import '../../../models/note.dart';
import '../../../services/ai_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/sketch_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/transcription_service.dart';
import '../generation_request_args.dart';

enum PipelineStep { text, audio, sketch, layout, completed, error }

class GenerationPipelineState {
  final PipelineStep currentStep;
  final int percentage;
  final bool isRunning;
  final GeneratedDocument? resultDocument;
  final String? error;

  const GenerationPipelineState({
    this.currentStep = PipelineStep.text,
    this.percentage = 15,
    this.isRunning = false,
    this.resultDocument,
    this.error,
  });

  GenerationPipelineState copyWith({
    PipelineStep? currentStep,
    int? percentage,
    bool? isRunning,
    GeneratedDocument? resultDocument,
    String? error,
    bool clearError = false,
  }) {
    return GenerationPipelineState(
      currentStep: currentStep ?? this.currentStep,
      percentage: percentage ?? this.percentage,
      isRunning: isRunning ?? this.isRunning,
      resultDocument: resultDocument ?? this.resultDocument,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GenerationPipelineController extends Notifier<GenerationPipelineState> {
  @override
  GenerationPipelineState build() => const GenerationPipelineState();

  Future<void> runPipeline(GenerationRequestArgs args) async {
    state = const GenerationPipelineState(
      isRunning: true,
      currentStep: PipelineStep.text,
      percentage: 20,
    );

    try {
      var note = args.note;
      final svgPaths = <String>[];

      // Etape 1 : Analyse du texte brut
      await Future.delayed(const Duration(milliseconds: 400));
      state = state.copyWith(percentage: 30);

      // Etape 1b : OCR Photos si presentes
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

      // Etape 2 : Retranscription audio Whisper si present
      if (note.audioPaths.isNotEmpty) {
        state = state.copyWith(
          currentStep: PipelineStep.audio,
          percentage: 45,
        );
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
      }

      // Etape 3 : Vectorisation des schemas joints
      if (note.rawSketchPaths.isNotEmpty) {
        state = state.copyWith(
          currentStep: PipelineStep.sketch,
          percentage: 65,
        );
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
      }

      // Etape 4 : Redaction et synthese IA finale
      state = state.copyWith(
        currentStep: PipelineStep.layout,
        percentage: 85,
      );

      final aiService = ref.read(aiServiceProvider);
      var document = await aiService.generate(
        note: note,
        format: args.format,
        mode: args.mode,
      );

      if (svgPaths.isNotEmpty) {
        document = document.copyWith(cleanedSketchSvgPaths: svgPaths);
      }

      // Sauvegarde automatique et definitive dans Firestore
      try {
        await ref.read(storageServiceProvider).saveDocument(document);
      } catch (_) {}

      // Fin de la generation reussie
      state = state.copyWith(
        isRunning: false,
        currentStep: PipelineStep.completed,
        percentage: 100,
        resultDocument: document,
      );
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        }
      }
      state = state.copyWith(
        isRunning: false,
        currentStep: PipelineStep.error,
        error: message,
      );
    }
  }
}

final generationPipelineControllerProvider =
    NotifierProvider<GenerationPipelineController, GenerationPipelineState>(
  GenerationPipelineController.new,
);
