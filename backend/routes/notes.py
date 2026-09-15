from fastapi import APIRouter

router = APIRouter()


@router.post("/")
def create_note():
    # TODO: enregistrer une note (texte/esquisse/image/audio)
    raise NotImplementedError


@router.get("/{note_id}")
def get_note(note_id: str):
    # TODO: récupérer une note par son id
    raise NotImplementedError
