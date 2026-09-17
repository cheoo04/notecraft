from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un plan de cours structuré : un titre de
cours, des parties et sous-parties numérotées, avec pour chacune un
court paragraphe expliquant ce qu'elle couvre et les points clés à
retenir.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""
