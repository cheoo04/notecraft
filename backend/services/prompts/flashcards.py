# backend/services/prompts/flashcards.py

"""Prompt de generation de Flashcards de revision active au format JSON."""

from .style_guide import DEPTH_GUIDE, STYLE_GUIDE


def build_prompt(note_content: str) -> str:
    return f"""
Transforme la note de cours suivante en un paquet de 6 à 10 flashcards de révision active pour un étudiant ou élève-ingénieur.

Consignes strictes de contenu :
- Recto : Une question précise, un défi intellectuel, ou un cas d'application concret (ex: "Quelle est la différence fondamentale entre X et Y ?" ou "Dans quel cas utilise-t-on Z ?").
- Verso : Une réponse claire, rigoureuse et concise, avec les mécanismes sous le capot, les ordres de grandeur ou les formules nécessaires.
- Pas de questions triviales ou superficielles : cible les notions susceptibles de tomber aux partiels.

Consigne impérative de format :
Réponds UNIQUEMENT avec un tableau JSON valide au format exact ci-dessous, sans aucun texte avant ni après, et sans bloc de code markdown :

[
  {{"recto": "Question 1", "verso": "Réponse détaillée 1"}},
  {{"recto": "Question 2", "verso": "Réponse détaillée 2"}}
]

{DEPTH_GUIDE}

{STYLE_GUIDE}

Note d'origine :
{note_content}
"""