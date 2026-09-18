import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/document.dart';
import '../../../services/ai_service.dart';
import '../../../services/storage_service.dart';
import '../generation_request_args.dart';

/// Écran 4 — Traitement & progression.
/// V1 : appel synchrone au backend (voir ai_service.dart). Le vrai
/// traitement en arrière-plan avec notification pour le mode affiné
/// viendra dans une itération suivante.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    final args = widget.args;
    if (args == null) return;

    try {
      final aiService = ref.read(aiServiceProvider);
      final document = await aiService.generate(
        note: args.note,
        format: args.format,
        mode: args.mode,
      );

      // La sauvegarde du document ne doit jamais empêcher d'afficher le
      // résultat : on l'isole dans son propre try/catch.
      try {
        await ref.read(storageServiceProvider).saveDocument(document);
      } catch (_) {
        // Best-effort : le document reste affichable même si la sauvegarde
        // Firestore échoue (hors-ligne, règles non configurées, etc.).
      }

      if (!mounted) return;
      context.replace('/document/${document.id}', extra: document);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null) {
      return const Scaffold(body: Center(child: Text('Aucune requête reçue')));
    }

    final isAffine = widget.args!.mode == GenerationMode.affine;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error == null) ...[
                const CircularProgressIndicator(color: AppColors.accentTeal),
                const SizedBox(height: 16),
                Text(
                  isAffine
                      ? 'Analyse affinée en cours...\nÇa peut prendre quelques minutes.'
                      : 'Génération en cours...',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Erreur : $_error\n\n'
                  'Vérifie que le backend tourne (uvicorn main:app --reload) '
                  'et que "adb reverse tcp:8000 tcp:8000" a bien été fait.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _generate();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
