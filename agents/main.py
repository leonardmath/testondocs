"""
FastAPI Main Application - Fase 1
Sistema de geração de documentos LaTeX
"""
from fastapi import FastAPI

app = FastAPI(
    title="LaTeX Document Generator",
    description="Sistema de geração de documentos LaTeX com validação e renderização",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "message": "LaTeX Document Generator API",
        "version": "1.0.0",
        "phase": "Fase 1",
        "status": "running"
    }

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "api"}
