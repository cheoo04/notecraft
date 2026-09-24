# backend/services/ai_client.py

import logging
import os
from openai import OpenAI

from .prompts.style_guide import STYLE_GUIDE

logger = logging.getLogger("notecraft.ai")

# Modeles candidats testes en cascade sur Groq
CANDIDATE_MODELS_EXPRESS = [
    os.environ.get("GROQ_MODEL_EXPRESS"),
    "openai/gpt-oss-20b",
    "llama-3.1-8b-instant",
    "llama-3.3-70b-versatile",
]

CANDIDATE_MODELS_AFFINE = [
    os.environ.get("GROQ_MODEL_AFFINE"),
    "openai/gpt-oss-120b",
    "llama-3.3-70b-versatile",
    "openai/gpt-oss-20b",
]


def _get_groq_client() -> OpenAI | None:
    api_key = os.environ.get("GROQ_API_KEY")
    if not api_key:
        return None
    return OpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=api_key,
    )


def _get_gemini_client() -> OpenAI | None:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return None
    return OpenAI(
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
        api_key=api_key,
    )


def _call_provider(client: OpenAI, model: str, prompt: str, max_tokens: int) -> str:
    response = client.chat.completions.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content or ""


def _call_anthropic(prompt: str, max_tokens: int) -> str:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("ANTHROPIC_API_KEY absente")
    from anthropic import Anthropic

    model = os.environ.get("ANTHROPIC_MODEL", "claude-3-5-sonnet-latest")
    client = Anthropic(api_key=api_key)
    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return "".join(
        block.text for block in response.content if block.type == "text"
    )


def execute_with_fallback(prompt: str, max_tokens: int = 2500, is_affine: bool = False) -> str:
    errors: list[str] = []

    # 1. Tentative Groq avec boucle de repli sur modeles candidats
    groq_client = _get_groq_client()
    if groq_client:
        candidate_models = CANDIDATE_MODELS_AFFINE if is_affine else CANDIDATE_MODELS_EXPRESS
        for model in candidate_models:
            if not model:
                continue
            try:
                return _call_provider(groq_client, model, prompt, max_tokens)
            except Exception as e:
                err = f"Groq ({model}) : {e}"
                logger.warning(err)
                errors.append(err)

    # 2. Fallback Google Gemini Flash
    gemini_client = _get_gemini_client()
    if gemini_client:
        gemini_model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
        try:
            return _call_provider(gemini_client, gemini_model, prompt, max_tokens)
        except Exception as e:
            err = f"Gemini ({gemini_model}) : {e}"
            logger.warning(err)
            errors.append(err)

    # 3. Fallback Anthropic si cle renseignee
    if os.environ.get("ANTHROPIC_API_KEY"):
        try:
            return _call_anthropic(prompt, max_tokens)
        except Exception as e:
            err = f"Anthropic : {e}"
            logger.warning(err)
            errors.append(err)

    if not errors:
        raise ValueError(
            "Aucune cle API configuree. Renseigne GROQ_API_KEY ou GEMINI_API_KEY dans le backend."
        )

    raise ValueError(
        "Tous les fournisseurs IA ont echoue. Details : " + " | ".join(errors)
    )


def compress_long_text(text: str, chunk_size: int = 4000) -> str:
    if len(text) <= 5000:
        return text

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


def generate(prompt: str, mode: str) -> str:
    is_affine = mode == "affine"

    if not is_affine:
        return execute_with_fallback(prompt, max_tokens=2200, is_affine=False)

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