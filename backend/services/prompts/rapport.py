from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un rapport structuré (introduction,
développement en parties, conclusion).

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""
