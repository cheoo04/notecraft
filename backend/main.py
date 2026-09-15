from dotenv import load_dotenv
from fastapi import FastAPI

load_dotenv()

from routes import export, generate, notes

app = FastAPI(title="NoteCraft API")

app.include_router(notes.router, prefix="/notes", tags=["notes"])
app.include_router(generate.router, prefix="/generate", tags=["generate"])
app.include_router(export.router, prefix="/export", tags=["export"])


@app.get("/health")
def health_check():
    return {"status": "ok"}
