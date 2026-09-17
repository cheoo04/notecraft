from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un exposé oral structuré : une
introduction qui pose le sujet et l'annonce du plan, un développement
en deux ou trois parties argumentées, et une conclusion qui synthétise
et ouvre sur une question ou une perspective.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""
