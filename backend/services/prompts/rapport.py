# backend/services/prompts/rapport.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Rédige un rapport d'étude approfondi, complet et exhaustif à partir de la note de cours suivante.

Directives impératives d'exhaustivité et de volume :
- Ne résume pas et n'élude aucun point : couvre l'INTÉGRALITÉ des concepts, algorithmes, protocoles et formules mentionnés dans la note d'origine.
- Chaque notion clé doit faire l'objet d'un développement complet avec ses explications techniques, sans se contenter d'une simple mention.
- Le rapport doit être dense, structuré et auto-porteur : un lecteur n'ayant pas assisté au cours doit pouvoir tout comprendre.

Structure du document :
1. Cadrage et Contexte : Origine du sujet, problématique centrale et enjeux techniques/scientifiques.
2. Analyse détaillée : Développe chaque grand thème dans des sections titrées numérotées. Explique les mécanismes sous le capot, compare les alternatives et intègre les formules nécessaires.
3. Bilan critique et Perspectives : Synthétise les acquis et ouvre sur les applications concrètes ou les recommandations.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""