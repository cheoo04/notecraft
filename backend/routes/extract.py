# backend/routes/extract.py

import base64
from fastapi import APIRouter, HTTPException

from models.schemas import ExtractDocumentRequest, ExtractDocumentResponse
from services.document_extractor import extract_text_from_file

router = APIRouter()


@router.post("/", response_model=ExtractDocumentResponse)
def extract_document_endpoint(request: ExtractDocumentRequest):
    try:
        file_bytes = base64.b64decode(request.file_base64)
    except Exception:
        raise HTTPException(status_code=400, detail="file_base64 invalide")

    try:
        text = extract_text_from_file(file_bytes, request.filename)
        # Suggere un titre propre a partir du nom de fichier sans l'extension
        clean_title = (
            request.filename.rsplit(".", 1)[0]
            .replace("_", " ")
            .replace("-", " ")
            .strip()
        )
        return ExtractDocumentResponse(
            extracted_text=text,
            suggested_title=clean_title if clean_title else None,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))