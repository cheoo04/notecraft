import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../models/document.dart';

/// Écran 5 — Résultat généré & export.
/// TODO: édition, export PDF/Word/SVG, rendu des schémas nettoyés.
class DocumentResultScreen extends StatelessWidget {
  final GeneratedDocument? document;

  const DocumentResultScreen({super.key, this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document généré')),
      body: document?.content == null
          ? const Center(child: Text('Aucun document reçu'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GptMarkdown(document!.content!),
            ),
    );
  }
}
