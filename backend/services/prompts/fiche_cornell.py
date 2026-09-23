# backend/services/prompts/fiche_cornell.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en une fiche de révision structurée selon la méthode Cornell, spécialement adaptée à la lecture sur smartphone :

Structure impérative :
1. En-tête : Titre clair du cours et objectif pédagogique en une phrase.
2. Définitions clés : Place les concepts fondamentaux dans des blocs de citation (commençant par '>') pour qu'ils ressortent visuellement.
3. Questions repères et développements :
   - Pour chaque notion clé, pose la question de révision (colonne repère Cornell) en sous-titre (###).
   - Développe immédiatement la réponse et les explications en dessous avec clarté, formules et exemples.
   - N'utilise JAMAIS de tableau pour mettre en vis-à-vis des paragraphes de texte : sur mobile, tout doit défiler verticalement.
4. Synthèse finale (Le résumé de bas de page Cornell) :
   - Termine par un encadré '### Synthèse essentielle' résumant les 3 à 5 points à mémoriser absolument pour l'examen.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""