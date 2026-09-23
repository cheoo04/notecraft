# backend/services/prompts/style_guide.py

STYLE_GUIDE = """
Consignes de style impératives :
- N'utilise JAMAIS de tiret cadratin (—) ni de demi-cadratin (–). Utilise exclusivement des deux-points (:), des virgules, des parenthèses ou de simples tirets courts (-).
- N'utilise JAMAIS de tableau Markdown pour afficher du texte rédigé ou de longues explications. Sur mobile, privilégie une hiérarchie verticale claire avec des sous-titres nets.
- Mets en valeur les définitions fondamentales, formules et axiomes avec des blocs de citation (débutant par >).
- Bannis tout ton de vulgarisation simpliste ou enfantin : écris avec la rigueur d'un cours d'école d'ingénieurs ou d'université scientifique.
- Reste précis sur le vocabulaire technique, sans paraphraser ni affaiblir les concepts.
"""

DEPTH_GUIDE = """
Consignes de profondeur et de rigueur d'ingénierie :
- Si la note aborde des technologies, algorithmes, protocoles ou systèmes (ex: IoT, réseaux, architecture matérielle, complexité algorithmique, sécurité) :
  1. Origine et Contexte : Explique systématiquement quel problème technique ou matériel précis cet outil est venu résoudre, et pourquoi les solutions préexistantes étaient inadaptées.
  2. Fonctionnement interne : Détaille les mécanismes sous le capot (pile de couches, gestion des ressources, mémoire, consommation électrique, complexité temporelle/spatiale O(f(n)), etc.).
  3. Matrice de compromis et Alternatives : Mentionne les technologies concurrentes ou complémentaires, et explique clairement les critères de choix (ex: latence vs autonomie, mémoire vs vitesse).
  4. Mise en pratique : Ajoute les contraintes concrètes d'implémentation et de gestion que doit connaître un futur ingénieur.
- Le document généré ne doit jamais se contenter de lister des termes : il doit donner les clés de compréhension globale du système.
"""