"""
Interprète une esquisse à main levée (image PNG envoyée depuis Flutter)
et la reconstruit en SVG propre, via un modèle multimodal.

Approche V1 (réaliste, cf. étude de faisabilité) : pas de vectorisation
pixel par pixel comme Nebo/MyScript (des décennies de R&D dédiée), mais
un seul appel à un modèle multimodal existant qui renvoie à la fois le
SVG reconstruit ET une courte description structurée des relations du
schéma (ex. "A -> B, B -> C") — cette description est destinée à être
réinjectée dans le prompt de génération du document (étape 3), pour
éviter un second appel IA dédié uniquement à la description.

Suit le même choix de fournisseur que ai_client.py (variable
AI_PROVIDER), avec des modèles vision spécifiques :
- "groq"      : qwen/qwen3.6-27b (vision-capable, gratuit/développeur —
                voir console.groq.com/docs/vision)
- "anthropic" : claude-sonnet-5 (déjà utilisé en mode affiné, vision
                native)

Les identifiants de modèle vision Groq changent régulièrement, comme les
modèles texte (voir ai_client.py) : vérifier console.groq.com/docs/vision
si le modèle par défaut ci-dessous ne répond plus, et l'ajuster via
GROQ_MODEL_VISION sans changer ce fichier.
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


_PROMPT = """Tu vois un schéma dessiné à main levée par un·e étudiant·e (trait noir sur fond blanc).

Fais deux choses, et réponds UNIQUEMENT avec un objet JSON valide au format exact suivant, sans aucun texte avant ou après :

{
  "svg": "<code SVG complet et valide ici>",
  "description": "<description courte et structurée des relations, une ligne par relation, ex. 'A -> B', 'B contient C'>"
}

Pour le SVG :
- Reconstruit proprement les formes (rectangles, cercles, flèches, texte) que tu identifies dans le croquis, sans copier le tracé brut
- Utilise un viewBox de "0 0 400 300"
- Formes en noir (#000000) sur fond transparent, traits fins (stroke-width 1.5 à 2)
- N'invente pas d'éléments qui ne sont pas dans le croquis

Pour la description :
- Une ligne par relation ou élément clé identifié
- Reste factuel, pas d'interprétation au-delà de ce qui est visible
"""


def interpret_sketch(image_bytes: bytes) -> dict:
    """
    Envoie l'image du croquis au modèle vision et renvoie
    {"svg": str, "description": str}.
    Lève ValueError si la réponse n'est pas exploitable.
    """
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    if PROVIDER == "anthropic":
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
        raw = "".join(
            block.text for block in response.content if block.type == "text"
        )
    else:
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
        raw = response.choices[0].message.content

    return _parse_response(raw)


def _parse_response(raw: str) -> dict:
    # Certains modèles enveloppent le JSON dans un bloc ```json malgré la
    # consigne — on l'extrait au besoin plutôt que d'échouer bêtement.
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if not match:
        raise ValueError(f"Réponse du modèle non exploitable (pas de JSON) : {raw[:200]}")
    data = json.loads(match.group(0))
    if "svg" not in data or "description" not in data:
        raise ValueError(f"JSON incomplet renvoyé par le modèle : {data}")
    return data
