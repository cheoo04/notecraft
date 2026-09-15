"""
Interprète une esquisse à main levée (tracés capturés côté Flutter)
et régénère un schéma propre.

Approche V1 (réaliste, cf. étude de faisabilité) : ne pas tenter de
vectoriser au pixel près comme Nebo/MyScript (20 ans de R&D), mais
utiliser un modèle multimodal existant pour comprendre la structure
du schéma (formes, relations, texte associé) et régénérer un rendu
propre en SVG ou en code de diagramme (ex. Mermaid).
"""


def interpret(strokes: list) -> str:
    # TODO: envoyer l'image du tracé à un modèle multimodal (ex. Claude)
    # avec une consigne du type : "décris les formes et leurs relations,
    # puis génère un SVG propre équivalent"
    raise NotImplementedError
