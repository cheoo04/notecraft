# backend/main.py

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

from routes import export, generate, notes, ocr, sketch, transcribe

app = FastAPI(title="NoteCraft API")

# Middleware CORS indispensable pour le Web (sans aucun impact sur le mobile)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(notes.router, prefix="/notes", tags=["notes"])
app.include_router(generate.router, prefix="/generate", tags=["generate"])
app.include_router(export.router, prefix="/export", tags=["export"])
app.include_router(sketch.router, prefix="/sketch", tags=["sketch"])
app.include_router(transcribe.router, prefix="/transcribe", tags=["transcribe"])
app.include_router(ocr.router, prefix="/ocr", tags=["ocr"])


@app.get("/health")
def health_check():
    return {"status": "ok"}