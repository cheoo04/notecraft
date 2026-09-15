import 'package:flutter/material.dart';

/// Écran 3 — Configuration du format & du mode.
/// TODO: grille de formats (résumé/rapport/exposé/cours/fiche),
/// segmented control Express / Affiné (distinction par teal vs gris neutre,
/// pas de jaune/or).
class GenerationConfigScreen extends StatelessWidget {
  const GenerationConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: const Center(child: Text('TODO: choix du format + mode Express/Affiné')),
    );
  }
}
