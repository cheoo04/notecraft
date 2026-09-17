"""
Point d'accès unique à l'API IA de génération.

Centraliser l'appel ici permet de changer de fournisseur (ou plus tard
de passer à un modèle auto-hébergé) sans toucher aux routes ni au code
Flutter : seule cette fonction change.

Fournisseur choisi via la variable d'environnement AI_PROVIDER :
- "groq"      (par défaut) : gratuit, modèles open source hébergés par
                Groq, largement suffisant pour développer et tester
- "anthropic" : payant, meilleure qualité de rédaction, à activer
                quand la qualité du rendu devient prioritaire

Les identifiants de modèle Groq changent régulièrement (dépréciations,
nouveaux modèles) : vérifier console.groq.com/docs/models si les
valeurs par défaut ci-dessous ne répondent plus, et les ajuster via les
variables d'environnement GROQ_MODEL_EXPRESS / GROQ_MODEL_AFFINE sans
changer ce fichier.
"""

import os

from .prompts.style_guide import STYLE_GUIDE

PROVIDER = os.environ.get("AI_PROVIDER", "groq")

if PROVIDER == "anthropic":
    from anthropic import Anthropic

    _client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
    EXPRESS_MODEL = "claude-haiku-4-5-20251001"
    AFFINE_MODEL = "claude-sonnet-5"
else:
    from openai import OpenAI

    _client = OpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=os.environ.get("GROQ_API_KEY"),
    )
    EXPRESS_MODEL = os.environ.get("GROQ_MODEL_EXPRESS", "openai/gpt-oss-20b")
    AFFINE_MODEL = os.environ.get("GROQ_MODEL_AFFINE", "openai/gpt-oss-120b")


def generate(prompt: str, mode: str) -> str:
    if mode == "express":
        return _single_pass(prompt, EXPRESS_MODEL, max_tokens=2000)

    draft = _single_pass(prompt, AFFINE_MODEL, max_tokens=3000)
    refine_prompt = f"""
Voici un premier brouillon de document. Relis-le et corrige tout ce qui
pourrait trahir un rendu IA générique.

{STYLE_GUIDE}

Renvoie uniquement la version corrigée, sans commentaire ni préambule.

Brouillon :
{draft}
"""
    return _single_pass(refine_prompt, AFFINE_MODEL, max_tokens=3000)


def _single_pass(prompt: str, model: str, max_tokens: int) -> str:
    if PROVIDER == "anthropic":
        response = _client.messages.create(
            model=model,
            max_tokens=max_tokens,
            messages=[{"role": "user", "content": prompt}],
        )
        return "".join(
            block.text for block in response.content if block.type == "text"
        )

    response = _client.chat.completions.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content
