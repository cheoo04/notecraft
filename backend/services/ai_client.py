# backend/services/ai_client.py

import logging
import os
from openai import OpenAI

from .prompts.style_guide import STYLE_GUIDE

logger = logging.getLogger("notecraft.ai")

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


def _call_provider_with_continuation(client: OpenAI, model: str, prompt: str, max_tokens: int) -> str:
    """
    Appelle le modele et si la reponse est tronquee par la limite de tokens
    (finish_reason == 'length'), demande automatiquement la suite et fusionne.
    """
    messages = [{"role": "user", "content": prompt}]
    content_chunks = []

    for _ in range(2):
        response = client.chat.completions.create(
            model=model,
            max_tokens=max_tokens,
            messages=messages,
        )
        choice = response.choices[0]
        chunk = choice.message.content or ""
        content_chunks.append(chunk)

        # Si le modele a fini naturellement, on s'arrete
        if choice.finish_reason != "length":
            break

        # S'il a ete coupe en plein vol, on lui demande de finir
        logger.info(f"Document tronque sur {model}, demande de continuation automatique...")
        messages.append({"role": "assistant", "content": chunk})
        messages.append({
            "role": "user",
            "content": "Continue la redaction exactement la ou tu t'es arrete, sans repeter ce qui precede et en menant le document jusqu'a sa conclusion complete."
        })

    return "".join(content_chunks)


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


def execute_with_fallback(prompt: str, max_tokens: int = 3000, is_affine: bool = False) -> str:
    errors: list[str] = []

    # 1. Tentative Groq avec boucle de repli et auto-continuation
    groq_client = _get_groq_client()
    if groq_client:
        candidate_models = CANDIDATE_MODELS_AFFINE if is_affine else CANDIDATE_MODELS_EXPRESS
        for model in candidate_models:
            if not model:
                continue
            try:
                return _call_provider_with_continuation(groq_client, model, prompt, max_tokens)
            except Exception as e:
                err = f"Groq ({model}) : {e}"
                logger.warning(err)
                errors.append(err)

    # 2. Fallback Google Gemini Flash
    gemini_client = _get_gemini_client()
    if gemini_client:
        gemini_model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
        try:
            return _call_provider_with_continuation(gemini_client, gemini_model, prompt, max_tokens)
        except Exception as e:
            err = f"Gemini ({gemini_model}) : {e}"
            logger.warning(err)
            errors.append(err)

    # 3. Fallback Anthropic
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


def generate(prompt: str, mode: str, is_long_document: bool = False) -> str:
    is_affine = mode == "affine"

    # Plafond de 7000 tokens pour les rapports et documents massifs
    token_limit = 7000 if is_long_document else 3000

    if not is_affine:
        return execute_with_fallback(prompt, max_tokens=token_limit, is_affine=False)

    draft = execute_with_fallback(prompt, max_tokens=token_limit, is_affine=True)

    refine_prompt = f"""
Voici un premier brouillon de document d'etude.
Relis-le et supprime tout ce qui pourrait trahir un style d'IA generique :
- Conserve l'INTEGRALITE des explications, formules, exemples et sections sans les raccourcir.
- Remplace tout tiret cadratin ou demi-cadratin residuel par deux-points, virgules ou parentheses.
- Assure-toi que la conclusion et les recommandations sont menees a leur terme complet.

{STYLE_GUIDE}

Renvoie exclusivement la version amelioree et finalisee, sans preambule ni commentaire.

Brouillon :
{draft}
"""
    return execute_with_fallback(refine_prompt, max_tokens=token_limit, is_affine=True)