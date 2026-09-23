# backend/services/prompts/expose.py

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note suivante en un support de présentation orale structuré, destiné à être prononcé devant un auditoire ou un jury.

Directives impératives :
1. Accroche et annonce du sujet : Une introduction dynamique, facile à dire à haute voix, avec l'annonce claire de l'angle choisi.
2. Développement en deux ou trois parties équilibrées :
   - Pour chaque partie, indique un repère de temps estimé (ex. 3 minutes).
   - Rédige des phrases adaptées au rythme de la parole, en intégrant des transitions orales explicites entre chaque partie.
3. Conclusion et ouverture : Un mot de fin percutant ouvrant sur un débat ou une perspective.
4. Questions probables : Deux questions susceptibles d'être posées par l'auditoire après la présentation, avec les éléments de réponse.

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""