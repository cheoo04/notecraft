"""
Point d'entrée FastAPI reconnu nativement par Vercel (zero-config) :
placé à la racine du dossier backend/ (= Root Directory du projet Vercel),
Vercel le détecte automatiquement et route TOUTES les requêtes dessus,
en conservant le vrai chemin (/health, /notes, /generate, ...).
"""

from main import app  # noqa: F401
