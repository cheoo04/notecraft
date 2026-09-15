import 'package:flutter/material.dart';

/// Écran 2 — Page blanche & capture multi-modale.
/// TODO: zone de texte auto-extensible, canvas d'esquisse (CustomPainter),
/// bouton image, enregistreur audio (limite 30 min).
class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brouillon automatique')),
      body: const Center(child: Text('TODO: éditeur de note (texte/esquisse/image/audio)')),
    );
  }
}
