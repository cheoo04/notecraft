# backend/routes/transcribe.py

import base64
from fastapi import APIRouter, HTTPException

from models.schemas import TranscribeRequest, TranscribeResponse
from services.transcription import transcribe_audio

router = APIRouter()


@router.post("/", response_model=TranscribeResponse)
def transcribe_endpoint(request: TranscribeRequest):
    try:
        audio_bytes = base64.b64decode(request.audio_base64)
    except Exception:
        raise HTTPException(status_code=400, detail="audio_base64 invalide")

    try:
        text = transcribe_audio(audio_bytes, request.filename)
        return TranscribeResponse(text=text)
    except ValueError as e:
        raise HTTPException(status_code=502, detail=str(e))