# backend/services/ai_client.py

"""
Moteur IA hybride avec :
1. Cascade de fallback automatique : Groq -> Google Gemini Flash -> Anthropic.
2. Pipeline de fragmentation (Map-Reduce) pour les notes denses et transcriptions de 30 min.
3. Mode Express (1 passe rapide) et Mode Affiné (2 passes avec relecture de style).
"""

import logging
import os
import re
from openai import OpenAI

from .prompts.style_guide import STYLE_GUIDE

logger = logging.getLogger("notecraft.ai")

# 1. Configuration des cles et modeles
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY")

# Modeles Groq configurables par variables d'environnement
GROQ_MODEL_EXPRESS = os.environ.get("GROQ_MODEL_EXPRESS", "llama-3.3-70b-versatile")
GROQ_MODEL_AFFINE = os.environ.get("GROQ_MODEL_AFFINE", "llama-3.3-70b-versatile")

# Modele Gemini (endpoint compatible OpenAI de Google AI Studio)
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")

# Modele Anthropic
ANTHROPIC_MODEL = os.environ.get("ANTHROPIC_MODEL", "claude-3-5-sonnet-latest")


# 2. Clients SDK initialises a la volee
def _get_groq_client() -> OpenAI | None:
    if not GROQ_API_KEY:
        return None
    return OpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=GROQ_API_KEY,
    )


def _get_gemini_client() -> OpenAI | None:
    if not GEMINI_API_KEY:
        return None
    # Google AI Studio propose un endpoint natif 100% compatible avec l'API OpenAI
    return OpenAI(
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
        api_key=GEMINI_API_KEY,
    )


def _call_provider(client: OpenAI, model: str, prompt: str, max_tokens: int) -> str:
    response = client.chat.completions.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content or ""


def _call_anthropic(prompt: str, max_tokens: int) -> str:
    from anthropic import Anthropic

    client = Anthropic(api_key=ANTHROPIC_API_KEY)
    response = client.messages.create(
        model=ANTHROPIC_MODEL,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return "".join(
        block.text for block in response.content if block.type == "text"
    )


def execute_with_fallback(prompt: str, max_tokens: int = 2500, is_affine: bool = False) -> str:
    """
    Tente l'appel sur Groq (ultra-rapide).
    En cas d'erreur de quota (429), de timeout ou de panne, bascule sur Gemini Flash (1M tokens).
    Puis sur Anthropic si renseigne.
    """
    errors: list[str] = []

    # 1. Tentative Groq
    groq_client = _get_groq_client()
    if groq_client:
        model = GROQ_MODEL_AFFINE if is_affine else GROQ_MODEL_EXPRESS
        try:
            return _call_provider(groq_client, model, prompt, max_tokens)
        except Exception as e:
            err_msg = f"Groq ({model}) echec : {e}"
            logger.warning(err_msg)
            errors.append(err_msg)

    # 2. Fallback Google Gemini Flash
    gemini_client = _get_gemini_client()
    if gemini_client:
        try:
            return _call_provider(gemini_client, GEMINI_MODEL, prompt, max_tokens)
        except Exception as e:
            err_msg = f"Gemini Flash ({GEMINI_MODEL}) echec : {e}"
            logger.warning(err_msg)
            errors.append(err_msg)

    # 3. Fallback Anthropic
    if ANTHROPIC_API_KEY:
        try:
            return _call_anthropic(prompt, max_tokens)
        except Exception as e:
            err_msg = f"Anthropic ({ANTHROPIC_MODEL}) echec : {e}"
            logger.warning(err_msg)
            errors.append(err_msg)

    raise RuntimeError(
        "Tous les fournisseurs IA ont echoue. Details : " + " | ".join(errors)
    )


# 3. Fragmentation pour les cours longs (Map-Reduce)
def compress_long_text(text: str, chunk_size: int = 4000) -> str:
    """
    Decoupe un texte dense (ex: transcription audio 30 min) en segments,
    extrait les points techniques de chaque segment, puis les reunit.
    """
    if len(text) <= 5000:
        return text

    # Decoupage par paragraphes pour ne pas couper au milieu d'une phrase
    paragraphs = text.split("\n")
    chunks: list[str] = []
    current_chunk: list[str] = []
    current_len = 0

    for p in paragraphs:
        if current_len + len(p) > chunk_size and current_chunk:
            chunks.append("\n".join(current_chunk))
            current_chunk = [p]
            current_len = len(p)
        else:
            current_chunk.append(p)
            current_len += len(p) + 1

    if current_chunk:
        chunks.append("\n".join(current_chunk))

    extracted_sections: list[str] = []
    for i, chunk in enumerate(chunks):
        extract_prompt = f"""
Voici un extrait (partie {i+1}/{len(chunks)}) d'un cours universitaire ou d'ingenieur.
Extrais sous forme dense tous les faits techniques, formules, protocoles, definitions et raisonnements cles.
Ne perds aucun detail technique essentiel. Sois direct et concis, sans phrase d'introduction.

Extrait :
{chunk}
"""
        extracted = execute_with_fallback(extract_prompt, max_tokens=1000)
        extracted_sections.append(f"--- Partie {i+1} ---\n{extracted}")

    return "\n\n".join(extracted_sections)


# 4. Point d'entree principal de generation
def generate(prompt: str, mode: str) -> str:
    is_affine = mode == "affine"

    if not is_affine:
        # Mode Express : 1 passe directe avec fallback
        return execute_with_fallback(prompt, max_tokens=2200, is_affine=False)

    # Mode Affine : Passe 1 (Brouillon approfondi) + Passe 2 (Relecture de style)
    draft = execute_with_fallback(prompt, max_tokens=3000, is_affine=True)

    refine_prompt = f"""
Voici un premier brouillon de document d'etude.
Relis-le et supprime tout ce qui pourrait trahir un style d'IA generique :
- Remplace tout tiret cadratin ou demi-cadratin residuel par deux-points, virgules ou parentheses.
- Assure-toi de la densite technique et de la precision du vocabulaire.
- Conserve tous les exemples, formules et definitions.

{STYLE_GUIDE}

Renvoie exclusivement la version amelioree et finalisee, sans preambule ni commentaire.

Brouillon :
{draft}
"""
    return execute_with_fallback(refine_prompt, max_tokens=3000, is_affine=True)