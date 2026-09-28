# backend/routes/generate.py

import json
import re
from fastapi import APIRouter, HTTPException

from models.schemas import GenerateRequest, GenerateResponse
from services import ai_client
from services.prompts import (
    expose,
    fiche_cornell,
    flashcards,
    plan_de_cours,
    rapport,
    resume,
)

router = APIRouter()

_PROMPT_BUILDERS = {
    "resume": resume.build_prompt,
    "rapport": rapport.build_prompt,
    "expose": expose.build_prompt,
    "plan_de_cours": plan_de_cours.build_prompt,
    "fiche_de_revision": fiche_cornell.build_prompt,
    "flashcards": flashcards.build_prompt,
}


@router.post("/", response_model=GenerateResponse)
def generate_document(request: GenerateRequest):
    try:
        raw_content = request.note_content.strip()

        # On ne compresse que pour les textes massifs (> 20 000 caracteres, ex: cours de 30 pages)
        # pour eviter de couper des details dans un Rapport ou une Fiche de cours
        if len(raw_content) > 20000:
            raw_content = ai_client.compress_long_text(raw_content)

        full_note = f"{request.note_title}\n\n{raw_content}"
        build_prompt = _PROMPT_BUILDERS[request.format.value]

        prompt = build_prompt(full_note)

        # Rapport et Plan de cours recoivent le quota de tokens etendu (4500 tokens)
        is_long = request.format.value in ("rapport", "plan_de_cours")
        content = ai_client.generate(prompt, request.mode.value, is_long_document=is_long)

        # Nettoyage si le format est flashcards pour garantir un JSON pur
        if request.format.value == "flashcards":
            match = re.search(r"\[.*\]", content, re.DOTALL)
            if match:
                content = match.group(0)

        return GenerateResponse(document_id="local", status="pret", content=content)
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))