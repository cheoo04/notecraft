from .style_guide import STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un résumé clair et structuré. Un résumé
doit rester concis : condense l'essentiel, ne l'allonge pas.

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""
