# backend/routes/ocr.py

from fastapi import APIRouter, HTTPException

from models.schemas import OcrRequest, OcrResponse
from services.vision_ocr import extract_board_content

router = APIRouter()


@router.post("/", response_model=OcrResponse)
def ocr_endpoint(request: OcrRequest):
    try:
        text = extract_board_content(request.image_base64)
        return OcrResponse(extracted_text=text)
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))