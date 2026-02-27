"""Conexión a MongoDB Atlas para la app de Nutrición.

Usa variables de entorno para no hardcodear credenciales:
- MONGODB_URI: cadena de conexión completa de Mongo Atlas
- MONGODB_DB: nombre de la base de datos (por defecto: nutricion_hogar_bambi)
"""

from __future__ import annotations

import os
from typing import Any

from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.database import Database


# Cargar variables desde .env si existe
load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI")
DEFAULT_DB_NAME = "nutricion_hogar_bambi"
DB_NAME = os.getenv("MONGODB_DB", DEFAULT_DB_NAME)


if not MONGODB_URI:
    raise RuntimeError(
        "MONGODB_URI no está definido. Configura la variable de entorno con el connection string de Mongo Atlas."
    )


_client: MongoClient | None = None
_db: Database | None = None


def get_client() -> MongoClient:
    """Devuelve un cliente singleton de MongoDB.

    Usa la misma conexión en toda la app backend.
    """

    global _client
    if _client is None:
        _client = MongoClient(MONGODB_URI)
    return _client


def get_db() -> Database:
    """Devuelve la base de datos principal configurada para la app."""

    global _db
    if _db is None:
        _db = get_client()[DB_NAME]
    return _db


def get_collection(nombre: str) -> Any:
    """Atajo para obtener una colección por nombre (sedes, cargos, productos, etc.)."""

    return get_db()[nombre]


if __name__ == "__main__":
    # Pequeña prueba manual de conexión
    db = get_db()
    print("Conectado a la BD:", db.name)
    print("Colecciones actuales:", db.list_collection_names())
