# backend/services/transcription.py

"""
Transcription audio haute fidelite (cours francais/anglais)
via Whisper Large V3 heberge sur Groq.
"""

import io
import os
from openai import OpenAI


def transcribe_audio(audio_bytes: bytes, filename: str = "audio.m4a") -> str:
    api_key = os.environ.get("GROQ_API_KEY")
    if not api_key:
        raise ValueError("GROQ_API_KEY absente pour la transcription Whisper")

    client = OpenAI(
        base_url="https://api.groq.com/openai/v1",
        api_key=api_key,
    )

    audio_file = (filename, io.BytesIO(audio_bytes))

    try:
        # Premiere tentative : Whisper Large V3 officiel
        transcription = client.audio.transcriptions.create(
            file=audio_file,
            model="whisper-large-v3",
            language="fr",
            response_format="text",
        )
        return str(transcription).strip()
    except Exception as e1:
        # Fallback automatique sur Whisper Turbo si charge elevee
        try:
            audio_file = (filename, io.BytesIO(audio_bytes))
            transcription = client.audio.transcriptions.create(
                file=audio_file,
                model="whisper-large-v3-turbo",
                language="fr",
                response_format="text",
            )
            return str(transcription).strip()
        except Exception as e2:
            raise ValueError(f"Echec transcription Whisper : {e1} | {e2}") from e2