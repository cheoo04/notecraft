# NoteCraft

Transforme des notes libres (texte, esquisse, image, audio ≤ 30 min) en documents structurés : résumé, rapport, exposé, plan de cours, fiche de révision.

## Structure

- `lib/` — application Flutter (mobile-first)
- `backend/` — API FastAPI qui orchestre l'IA (transcription, interprétation des esquisses, génération)

## Démarrage

### Flutter

```bash
flutter pub get
flutter run
```

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

## État du projet

Ceci est le squelette initial : arborescence de dossiers, écrans stubs (7 écrans définis dans les maquettes), modèles de données, interfaces de services et routes backend avec `TODO` explicites à implémenter.

Design system : voir `lib/core/theme/app_theme.dart` (couleur d'accent teal `#0F766E`, pas de jaune/or).

Style de rédaction : voir `backend/services/prompts/style_guide.py` (pas de tiret cadratin, éviter le rendu "IA générique").
