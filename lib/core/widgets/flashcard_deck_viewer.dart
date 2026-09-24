// lib/core/widgets/flashcard_deck_viewer.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class FlashcardItem {
  final String recto;
  final String verso;

  const FlashcardItem({required this.recto, required this.verso});
}

class FlashcardDeckViewer extends StatefulWidget {
  final String rawJsonContent;

  const FlashcardDeckViewer({super.key, required this.rawJsonContent});

  @override
  State<FlashcardDeckViewer> createState() => _FlashcardDeckViewerState();
}

class _FlashcardDeckViewerState extends State<FlashcardDeckViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  List<FlashcardItem> _cards = [];
  int _currentIndex = 0;
  bool _showVerso = false;

  @override
  void initState() {
    super.initState();
    _parseCards();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  void _parseCards() {
    try {
      final decoded = jsonDecode(widget.rawJsonContent) as List;
      _cards = decoded.map((c) {
        final map = c as Map<String, dynamic>;
        return FlashcardItem(
          recto: map['recto'] as String? ?? 'Question',
          verso: map['verso'] as String? ?? 'Réponse',
        );
      }).toList();
    } catch (_) {
      _cards = [
        const FlashcardItem(
          recto: 'Erreur d\'interprétation des cartes',
          verso: 'Le format généré n\'a pas pu être converti en JSON valide.',
        )
      ];
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.selectionClick();
    if (_showVerso) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showVerso = !_showVerso);
  }

  void _goTo(int index) {
    if (index < 0 || index >= _cards.length) return;
    HapticFeedback.lightImpact();
    if (_showVerso) {
      _flipController.reverse();
      _showVerso = false;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Center(child: Text('Aucune flashcard disponible'));
    }

    final card = _cards[_currentIndex];

    return Column(
      children: [
        // En-tete de progression
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CARTE ${_currentIndex + 1} / ${_cards.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _showVerso
                    ? AppColors.accentTealLight
                    : AppColors.neutralFill,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _showVerso ? 'RÉPONSE (VERSO)' : 'QUESTION (RECTO)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      _showVerso ? AppColors.accentTeal : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Carte 3D a retourner au tap
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final isUnder = angle > (math.pi / 2);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isUnder
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _CardSurface(
                          title: 'Réponse & Explication',
                          text: card.verso,
                          isAnswer: true,
                        ),
                      )
                    : _CardSurface(
                        title: 'Question de révision',
                        text: card.recto,
                        isAnswer: false,
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // Indicateur d'action
        const Text(
          'Touche la carte pour la retourner',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Boutons de navigation Precedent / Suivant
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Précédente'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.neutralBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _currentIndex < _cards.length - 1
                    ? () => _goTo(_currentIndex + 1)
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text(
                  'Suivante',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardSurface extends StatelessWidget {
  final String title;
  final String text;
  final bool isAnswer;

  const _CardSurface({
    required this.title,
    required this.text,
    required this.isAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAnswer ? Colors.white : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnswer ? AppColors.accentTeal : AppColors.neutralBorder,
          width: isAnswer ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAnswer
                ? AppColors.accentTeal.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isAnswer ? AppColors.accentTeal : AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: isAnswer ? 15 : 18,
              fontWeight: isAnswer ? FontWeight.w500 : FontWeight.w700,
              color: AppColors.inkDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
