# backend/services/vision_ocr.py

"""
Service d'extraction de contenu sur photo de tableau ou diapositive (OCR multimodal)
via Groq Vision (Qwen) avec repli automatique sur Gemini Flash.
"""

import os
from openai import OpenAI

_OCR_PROMPT = """Tu analyses la photo d'un tableau d'amphi ou d'une diapositive de cours prise par un étudiant.

Consignes strictes d'extraction :
1. Extrais avec rigueur tout le texte visible, sans inventer ni tronquer.
2. Pour toute formule mathématique, physique ou chimique, transcris-la rigoureusement en syntaxe LaTeX standard entre délimiteurs $...$ ou \\[ ... \\].
3. Pour les schémas, organigrammes ou graphes dessinés, décris succinctement leur structure logique et les relations entre les blocs (ex: [Module A] -> [Module B]).
4. Sois direct et exhaustif : renvoie uniquement le contenu extrait, sans préambule ni formule de politesse.
"""


def extract_board_content(image_base64: str) -> str:
    groq_key = os.environ.get("GROQ_API_KEY")
    gemini_key = os.environ.get("GEMINI_API_KEY")

    # 1. Tentative Groq Vision
    if groq_key:
        try:
            client = OpenAI(
                base_url="https://api.groq.com/openai/v1",
                api_key=groq_key,
            )
            model = os.environ.get("GROQ_MODEL_VISION", "qwen/qwen3.6-27b")
            response = client.chat.completions.create(
                model=model,
                max_tokens=2000,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": _OCR_PROMPT},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/jpeg;base64,{image_base64}"
                                },
                            },
                        ],
                    }
                ],
            )
            return response.choices[0].message.content or ""
        except Exception:
            pass

    # 2. Fallback Gemini Flash Vision
    if gemini_key:
        try:
            client = OpenAI(
                base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
                api_key=gemini_key,
            )
            gemini_model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
            response = client.chat.completions.create(
                model=gemini_model,
                max_tokens=2000,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": _OCR_PROMPT},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/jpeg;base64,{image_base64}"
                                },
                            },
                        ],
                    }
                ],
            )
            return response.choices[0].message.content or ""
        except Exception as e:
            raise ValueError(f"Echec OCR Vision : {e}") from e

    raise ValueError("Aucune clé API vision disponible (GROQ_API_KEY ou GEMINI_API_KEY).")