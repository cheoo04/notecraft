# backend/models/schemas.py

from enum import Enum
from pydantic import BaseModel


class DocumentFormat(str, Enum):
    resume = "resume"
    rapport = "rapport"
    expose = "expose"
    plan_de_cours = "plan_de_cours"
    fiche_de_revision = "fiche_de_revision"
    flashcards = "flashcards"


class GenerationMode(str, Enum):
    express = "express"
    affine = "affine"


class GenerateRequest(BaseModel):
    note_title: str
    note_content: str
    format: DocumentFormat
    mode: GenerationMode


class GenerateResponse(BaseModel):
    document_id: str
    status: str
    content: str | None = None


class SketchRequest(BaseModel):
    image_base64: str


class SketchResponse(BaseModel):
    svg: str
    description: str


class TranscribeRequest(BaseModel):
    audio_base64: str
    filename: str = "audio.m4a"


class TranscribeResponse(BaseModel):
    text: str


class OcrRequest(BaseModel):
    image_base64: str


class OcrResponse(BaseModel):
    extracted_text: str