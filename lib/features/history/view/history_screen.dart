import 'package:flutter/material.dart';

/// Écran 6 — Historique & régénération multi-format.
/// TODO: liste filtrable par matière, détail d'une note,
/// bouton "régénérer dans un autre format".
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des notes')),
      body: const Center(child: Text('TODO: liste des notes passées')),
    );
  }
}
