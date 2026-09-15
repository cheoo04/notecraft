import 'package:flutter/material.dart';

/// Écran 5 — Résultat généré & export.
/// TODO: aperçu du document (texte + schémas SVG nettoyés),
/// édition WYSIWYG, export PDF/Word/SVG.
class DocumentResultScreen extends StatelessWidget {
  const DocumentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document généré')),
      body: const Center(child: Text('TODO: aperçu du document + export')),
    );
  }
}
