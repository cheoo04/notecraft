from fastapi import APIRouter

router = APIRouter()


@router.get("/{document_id}/word")
def export_word(document_id: str):
    # TODO: génération .docx via python-docx (plus fiable que les libs Dart)
    raise NotImplementedError


@router.get("/{document_id}/svg")
def export_svg(document_id: str):
    # TODO: renvoyer les schémas vectorisés associés au document
    raise NotImplementedError
