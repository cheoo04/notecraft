import base64

from fastapi import APIRouter, HTTPException

from models.schemas import SketchRequest, SketchResponse
from services.sketch_interpreter import interpret_sketch

router = APIRouter()


@router.post("/", response_model=SketchResponse)
def vectorize_sketch(request: SketchRequest):
    """
    Reçoit un croquis (PNG en base64) et renvoie un SVG reconstruit + une
    description structurée des relations, en un seul appel au modèle
    vision (voir sketch_interpreter.py pour le détail du choix).
    """
    try:
        image_bytes = base64.b64decode(request.image_base64)
    except Exception:
        raise HTTPException(status_code=400, detail="image_base64 invalide")

    try:
        result = interpret_sketch(image_bytes)
    except ValueError as e:
        raise HTTPException(status_code=502, detail=str(e))

    return SketchResponse(svg=result["svg"], description=result["description"])
