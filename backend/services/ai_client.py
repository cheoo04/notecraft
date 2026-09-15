"""
Point d'accès unique à l'API IA de génération.

Centraliser l'appel ici permet, plus tard, de remplacer l'API externe
par un modèle auto-hébergé (fine-tuné en LoRA/QLoRA, servi via
llama.cpp/Ollama) sans changer les routes ni le code Flutter :
seule cette fonction change.
"""


def generate(prompt: str, mode: str) -> str:
    # TODO:
    # mode == "express" : un seul appel, réponse courte attendue
    # mode == "affine"  : plusieurs passes (brouillon -> relecture ->
    #                     vérification du style "non-IA", voir section 5.3
    #                     du cahier des charges)
    raise NotImplementedError
