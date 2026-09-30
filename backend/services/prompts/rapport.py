# backend/services/prompts/rapport.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Rédige un rapport d'étude approfondi, complet et rigoureusement mené à son terme à partir de la note de cours suivante.

Directives impératives d'achèvement et d'exhaustivité :
- Ne t'arrête jamais au milieu d'une liste ou d'un raisonnement : termine chaque point commencé et mène le document jusqu'à sa conclusion finale.
- Couvre l'INTÉGRALITÉ des concepts, algorithmes, protocoles et formules mentionnés dans la note d'origine.
- Chaque sous-partie doit être développée avec ses explications techniques et ses cas d'application réels.

Plan à respecter impérativement :
1. Cadrage et Contexte : Origine du sujet, problématique centrale et enjeux techniques/scientifiques.
2. Analyse détaillée : Développe chaque grand thème dans des sections titrées numérotées (ex. 2.1, 2.2). Explique les mécanismes, compare les alternatives et intègre les formules nécessaires.
3. Bilan critique et Recommandations opérationnelles :
   - 3.1 Synthèse des acquis fondamentaux.
   - 3.2 Recommandations opérationnelles (3 à 5 recommandations complètes et justifiées).
   - 3.3 Conclusion générale récapitulative.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""