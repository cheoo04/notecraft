from fastapi import APIRouter

from services import ai_client, sketch_interpreter, transcription

router = APIRouter()


@router.post("/")
def generate_document(note_id: str, format: str, mode: str):
    """
    Point d'entrée principal : reçoit une note, un format de sortie
    et un mode (express/affine), et retourne le document généré.

    - mode == "express" : une seule passe de génération, réponse rapide
    - mode == "affine"  : transcription + vectorisation des schémas +
                          plusieurs passes de génération/vérification,
                          traitement différé avec notification à la fin
    """
    # TODO:
    # 1. si audio présent -> transcription.transcribe(audio_path)
    # 2. si esquisse présente -> sketch_interpreter.interpret(strokes)
    # 3. assembler le prompt selon `format` (voir services/prompts/)
    # 4. appeler ai_client.generate(prompt, mode)
    raise NotImplementedError


@router.get("/{document_id}/status")
def get_generation_status(document_id: str):
    # TODO: statut d'une génération en mode affiné (en_cours/pret/echec)
    raise NotImplementedError
