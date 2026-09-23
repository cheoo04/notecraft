# backend/services/prompts/resume.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un résumé de cours clair, dense et pédagogique.

Directives de structure :
1. Titre et Problématique : En deux phrases, situe le domaine et la question centrale du cours.
2. Corps du résumé : Rédige deux à quatre paragraphes de texte suivi expliquant les principes fondamentaux avec rigueur. Développe les explications sans diluer l'information.
3. Notions incontournables : Mets en valeur les définitions ou formules indispensables sous forme d'encadrés débutant par '>'.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""