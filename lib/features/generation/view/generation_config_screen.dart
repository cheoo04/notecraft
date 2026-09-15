import 'package:flutter/material.dart';

import '../../../models/note.dart';

/// Écran 3 — Configuration du format & du mode.
/// TODO: grille de formats (résumé/rapport/exposé/cours/fiche),
/// segmented control Express / Affiné (distinction par teal vs gris neutre,
/// pas de jaune/or).
class GenerationConfigScreen extends StatelessWidget {
  final Note? note;

  const GenerationConfigScreen({super.key, this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: Center(
        child: Text(
          note == null
              ? 'Aucune note reçue'
              : 'Note reçue : "${note!.title}"\nTODO: choix du format + mode',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
