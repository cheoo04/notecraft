import 'package:flutter/material.dart';

/// Écran 1 — Accueil & prise de notes rapide.
/// TODO: liste des notes récentes, barre de recherche, capture rapide.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes notes & synthèses')),
      body: const Center(child: Text('TODO: liste des notes récentes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: naviguer vers /note/new
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
