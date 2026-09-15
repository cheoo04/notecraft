import 'package:flutter/material.dart';

/// Écran 7 — Réglages & préférences IA.
/// TODO: profil, ton par défaut, format favori, quota mode Affiné,
/// gestion du stockage audio.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: const Center(child: Text('TODO: préférences utilisateur')),
    );
  }
}
