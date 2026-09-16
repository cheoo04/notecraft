# La 404 est réglée — nouvelle erreur : 500

Bon signe : la requête arrive maintenant jusqu'à la bonne route (le fix
précédent a marché). Le 500 veut dire que le code Python plante à
l'intérieur de la route appelée. Sans le vrai traceback je ne peux que
proposer des hypothèses — voici comment trancher vite, puis les deux
causes les plus probables.

## 1. Regarde le vrai traceback (le plus rapide et le plus sûr)

```bash
vercel logs https://backend-beryl-two-39.vercel.app
```
ou dans le dashboard Vercel → ton projet "backend" → Deployments → le
déploiement courant → onglet "Logs" / "Runtime Logs". Le traceback Python
complet y est. Colle-le-moi, ça évite de deviner.

## 2. Teste en local avec le MÊME venv que celui utilisé pour la prod

```bash
cd ~/Projet/NoteToDoc/notecraft_skeleton/notecraft/backend
source ~/.venvs/notecraft-backend/bin/activate
uvicorn main:app --reload
```
puis, dans un autre terminal :
```bash
curl -X POST http://localhost:8000/generate/ \
  -H "Content-Type: application/json" \
  -d '{"note_title":"test","note_content":"ceci est un test","format":"resume","mode":"express"}'
```
- Si ça plante pareil en local → c'est un bug de code/dépendances, pas un
  souci propre à Vercel.
- Si ça marche en local → très probablement les variables d'environnement
  (`AI_PROVIDER`, `GROQ_API_KEY` ou `ANTHROPIC_API_KEY`) ne sont pas
  configurées côté Vercel (Project Settings → Environment Variables). Le
  `.env` local n'est jamais monté en prod, et ça ne t'a jamais été confirmé
  fait depuis qu'on a retiré `.env` du dépôt.

## 3. Piste concrète repérée dans requirements.txt

Ton `requirements.txt` utilise des bornes `>=` sans plafond sur tout :
`openai>=1.40.0` par exemple. Ton install locale a résolu vers
`openai-3.14.0` — un saut énorme depuis le plancher `1.40.0`. Vercel
réinstalle les dépendances à chaque build depuis ce même fichier, donc il
peut très bien retomber sur une version différente (ou la même,
selon la date du build) de celle que tu as testée. `ai_client.py` utilise
un pattern client OpenAI (`OpenAI(base_url=..., api_key=...)`,
`.chat.completions.create(...)`) qui est stable depuis longtemps, mais un
saut de version majeure (1.x → 3.x) peut changer des choses. Le
`requirements.txt` fourni ici fixe des versions exactes (celles que ton
install locale a réellement utilisées) pour au moins garantir que prod et
local tournent avec le même code — utile pour confirmer ou écarter cette
piste avec le test de l'étape 2.

## À faire

1. Remplace `backend/requirements.txt` par celui fourni ici (versions
   figées).
2. Vérifie/complète les Environment Variables sur Vercel (`AI_PROVIDER`,
   `GROQ_API_KEY`, `ANTHROPIC_API_KEY` selon ce que tu utilises).
3. `git add backend/requirements.txt && git commit -m "pin backend deps" && git push`
4. Si ça persiste, lance la commande `vercel logs` de l'étape 1 et
   colle-moi le traceback — je pourrai cibler directement la ligne qui
   plante plutôt que de multiplier les hypothèses.
