# backend/services/prompts/rapport.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un rapport d'étude rigoureux et argumenté.

Directives de structure :
1. Cadrage et Contexte : Présente l'origine du sujet, le périmètre analysé et la méthodologie employée.
2. Analyse détaillée : Développe l'argumentation en parties titrées. Explique les mécanismes, confronte les arguments et détaille les résultats ou concepts.
3. Synthèse critique et Recommandations : Conclus par un bilan objectif et formule des pistes de travail ou des recommandations concrètes.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""