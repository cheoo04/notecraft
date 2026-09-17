from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en fiche de révision selon la méthode Cornell :
une colonne de mots-clés/questions, une zone de notes détaillées, et un
résumé en bas de page.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""
