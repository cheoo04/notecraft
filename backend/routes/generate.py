from fastapi import APIRouter

from models.schemas import GenerateRequest, GenerateResponse
from services import ai_client
from services.prompts import expose, fiche_cornell, plan_de_cours, rapport, resume

router = APIRouter()

_PROMPT_BUILDERS = {
    "resume": resume.build_prompt,
    "rapport": rapport.build_prompt,
    "expose": expose.build_prompt,
    "plan_de_cours": plan_de_cours.build_prompt,
    "fiche_de_revision": fiche_cornell.build_prompt,
}


@router.post("/", response_model=GenerateResponse)
def generate_document(request: GenerateRequest):
    """
    Reçoit le contenu d'une note, un format de sortie et un mode, et
    retourne le document généré.

    V1 : traitement synchrone dans les deux modes (le mode affiné prend
    juste plus de temps à répondre). Le vrai traitement en arrière-plan
    avec notification viendra une fois ce flux de base validé.
    """
    note_content = f"{request.note_title}\n\n{request.note_content}"
    build_prompt = _PROMPT_BUILDERS[request.format.value]

    prompt = build_prompt(note_content)
    content = ai_client.generate(prompt, request.mode.value)

    return GenerateResponse(document_id="local", status="pret", content=content)
