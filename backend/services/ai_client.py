def generate(prompt: str, mode: str, is_long_document: bool = False) -> str:
    is_affine = mode == "affine"

    # Plafond adapte : 4500 tokens pour les rapports longs, 2500 pour les fiches/resumes
    token_limit = 4500 if is_long_document else 2500

    if not is_affine:
        return execute_with_fallback(prompt, max_tokens=token_limit, is_affine=False)

    # Mode Affine : 2 passes avec marge suffisante
    draft = execute_with_fallback(prompt, max_tokens=token_limit, is_affine=True)

    refine_prompt = f"""
Voici un premier brouillon de document d'etude.
Relis-le et supprime tout ce qui pourrait trahir un style d'IA generique :
- Conserve l'INTEGRALITE des explications, formules, exemples et sections sans les raccourcir.
- Remplace tout tiret cadratin ou demi-cadratin residuel par deux-points, virgules ou parentheses.
- Assure-toi de la densite technique et de la precision du vocabulaire.

{STYLE_GUIDE}

Renvoie exclusivement la version amelioree et finalisee, sans preambule ni commentaire.

Brouillon :
{draft}
"""
    return execute_with_fallback(refine_prompt, max_tokens=token_limit, is_affine=True)