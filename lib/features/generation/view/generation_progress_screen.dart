import 'package:flutter/material.dart';

import '../controller/generation_config_controller.dart';
import '../generation_request_args.dart';

/// Écran 4 — Traitement & progression asynchrone.
/// TODO: brancher le vrai appel au backend (POST /generate), indicateur
/// circulaire réel, notification locale à la fin du mode Affiné.
class GenerationProgressScreen extends StatelessWidget {
  final GenerationRequestArgs? args;

  const GenerationProgressScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    if (args == null) {
      return const Scaffold(body: Center(child: Text('Aucune requête reçue')));
    }
    return Scaffold(
      body: Center(
        child: Text(
          'Génération "${formatLabel(args!.format)}" '
          '(${args!.mode.name}) pour "${args!.note.title}"\n'
          'TODO: appel réel au backend',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
