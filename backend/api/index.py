"""
Point d'entrée pour Vercel : expose l'app FastAPI définie dans main.py
comme fonction serverless. Ajoute le dossier backend/ (parent de api/)
au chemin Python pour que les imports absolus de main.py (routes,
services, models) continuent de fonctionner tels quels.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from main import app  # noqa: E402
