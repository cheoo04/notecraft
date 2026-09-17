"""
Consigne de style commune, à injecter dans tous les prompts de génération.
Reprend les exigences de la section 5.3 du cahier des charges :
un document qui ne "sent" pas l'IA.
"""

STYLE_GUIDE = """
Consignes de style impératives :
- N'utilise jamais le tiret cadratin (—). Remplace-le par une virgule,
  un point, ou reformule la phrase.
- Varie la longueur et la construction des phrases, évite les tournures
  robotiques ou trop lisses.
- N'utilise un tableau que s'il structure une vraie comparaison ou
  énumération, jamais par réflexe de mise en forme.
- Évite le sur-listage systématique : privilégie le texte suivi quand
  le contenu s'y prête.
- Écris comme un étudiant ou un professeur rédigerait réellement ce
  document, pas comme une IA générique.
"""

DEPTH_GUIDE = """
Consignes de profondeur du contenu :
- Ne te contente pas de reformuler ou raccourcir la note d'origine :
  développe chaque idée avec des explications claires, comme le ferait
  un bon professeur qui maîtrise le sujet.
- Ajoute le contexte ou les précisions utiles à la compréhension du
  sujet, même si la note d'origine ne les détaille pas explicitement,
  tant que ça reste cohérent avec ce qui est écrit.
- Le document final doit être plus complet et plus clair à lire que la
  note brute, jamais plus pauvre.
"""
