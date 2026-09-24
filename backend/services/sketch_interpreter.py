# backend/services/sketch_interpreter.py

"""
Interprète une esquisse à main levée (image PNG envoyée depuis Flutter)
et la reconstruit en SVG propre, via un modèle multimodal.
Gère les schémas relationnels, les flux, et les tableaux / grilles tracés à main levée.
Tolérant à l'écriture au doigt sur smartphone tout en reconnaissant les étiquettes tapées au clavier.
"""

import base64
import json
import os
import re

PROVIDER = os.environ.get("AI_PROVIDER", "groq")

if PROVIDER == "anthropic":
    from anthropic import Anthropic

    _client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
    VISION_MODEL = "claude-sonnet-5"
else:
    from openai import OpenAI

    _client = OpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=os.environ.get("GROQ_API_KEY"),
    )
    VISION_MODEL = os.environ.get("GROQ_MODEL_VISION", "qwen/qwen3.6-27b")


_PROMPT = """Tu analyses un schéma ou croquis d'étude réalisé par un étudiant (tracé noir et texte sur fond blanc).

L'image peut combiner des tracés à main levée au doigt, des étiquettes de texte dactylographiées ou des annotations manuscrites : interprète l'intention globale de l'étudiant avec précision et bienveillance.

Fais deux choses, et réponds UNIQUEMENT avec un objet JSON valide au format exact suivant, sans aucun texte avant ou après :

{
  "svg": "<code SVG complet et valide ici>",
  "description": "<description courte et structurée des relations ou du tableau, une ligne par élément, ex. 'A -> B', 'Tableau: Colonne 1 = ..., Colonne 2 = ...'>"
}

Consignes strictes pour le SVG :
1. Formes géométriques : Reconstruis proprement les formes (cercles réguliers, rectangles droits, flèches de connexion vectorielles nettes). Supprime les tremblements du doigt.
2. Tableaux et Grilles : Si le croquis esquisse un tableau ou une matrice, redessine une structure de tableau nette, avec des séparateurs alignés et des bordures soignées.
3. Typographie : Transcris tout mot ou symbole (qu'il soit tapé au clavier ou gribouillé au doigt) sous forme de texte vectoriel propre (<text>), parfaitement lisible et centré à l'intérieur de la forme ou de la cellule correspondante.
4. Style visuel :
   - viewBox de "0 0 400 300" (ou adapté si format panoramique).
   - Traits fins et nets (#0F766E ou #111827), fond transparent.
   - N'invente pas d'éléments majeurs qui ne figurent pas dans l'esquisse.

Consignes pour la description :
- Reste factuel, une ligne par relation (A -> B) ou par ligne de tableau.
- Cette description sera injectée dans le prompt pour que le modèle texte comprenne la structure.
"""


def interpret_sketch(image_bytes: bytes) -> dict:
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    if PROVIDER == "anthropic":
        try:
            response = _client.messages.create(
                model=VISION_MODEL,
                max_tokens=2000,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": "image/png",
                                    "data": image_b64,
                                },
                            },
                            {"type": "text", "text": _PROMPT},
                        ],
                    }
                ],
            )
        except Exception as e:
            raise ValueError(f"Appel vision Anthropic ({VISION_MODEL}) échoué : {e}") from e
        raw = "".join(
            block.text for block in response.content if block.type == "text"
        )
    else:
        try:
            response = _client.chat.completions.create(
                model=VISION_MODEL,
                max_tokens=2000,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": _PROMPT},
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/png;base64,{image_b64}"},
                            },
                        ],
                    }
                ],
            )
        except Exception as e:
            raise ValueError(f"Appel vision Groq ({VISION_MODEL}) échoué : {e}") from e
        raw = response.choices[0].message.content

    return _parse_response(raw)


def _parse_response(raw: str) -> dict:
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if not match:
        raise ValueError(f"Réponse vision non exploitable (pas de JSON) : {raw[:200]}")
    data = json.loads(match.group(0))
    if "svg" not in data or "description" not in data:
        raise ValueError(f"JSON incomplet renvoyé par le modèle vision : {data}")
    return data