"""Punto de entrada para ejecutar el backend con Uvicorn.

Este script es útil para empaquetar el backend como un ejecutable
con herramientas como PyInstaller.
"""

from __future__ import annotations

import uvicorn
from main import app


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=False)
