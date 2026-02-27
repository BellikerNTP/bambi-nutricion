"""API de FastAPI para la app de Nutrición Hogar Bambi.

Por ahora se enfoca en:
- Inventario (productos + historial de movimientos)
- Platos servidos (historial y registro de nuevos platos)
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, List, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from db import get_collection

app = FastAPI(title="Nutricion API", version="1.0.0")

# En caso de que luego quieras servir el front web, este CORS abierto ayuda en desarrollo.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------
# MODELOS Pydantic
# -----------------


class ProductoOut(BaseModel):
    id: str
    nombre: str
    categoria: str
    unidad: str
    stockMinimo: int
    cantidadActual: int
    estado: str


class MovimientoInventarioIn(BaseModel):
    tipo: str  # entrada | salida | transferencia
    productoId: str
    sedeId: str
    cantidad: int
    motivo: Optional[str] = None
    sedeOrigenId: Optional[str] = None
    sedeDestinoId: Optional[str] = None


class MovimientoInventarioOut(BaseModel):
    id: str
    fecha: datetime
    tipo: str
    producto: str
    cantidad: int
    motivo: Optional[str] = None
    origen: Optional[str] = None
    destino: Optional[str] = None


class IngredientePlato(BaseModel):
    productoId: str
    cantidad: float


class RegistroPlatoIn(BaseModel):
    fecha: Optional[datetime] = None
    sedeId: str
    cargoId: str
    nombrePlato: str
    cantidadPersonas: int
    ingredientes: List[IngredientePlato]
    observaciones: Optional[str] = None


class RegistroPlatoOut(BaseModel):
    id: str
    fecha: datetime
    sedeId: str
    cargoId: str
    nombrePlato: str
    cantidadPersonas: int
    observaciones: Optional[str] = None


# ---------
# ENDPOINTS
# ---------


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


# INVENTARIO


@app.get("/inventario/productos", response_model=List[ProductoOut])
def listar_productos(sedeId: str = Query(..., alias="sedeId")):
    productos_col = get_collection("productos")

    docs = list(productos_col.find({"sedeId": sedeId}))
    resultados: List[dict[str, Any]] = []
    for d in docs:
        resultados.append(
            {
                "id": d.get("_id"),
                "nombre": d.get("nombre"),
                "categoria": d.get("categoria"),
                "unidad": d.get("unidad"),
                "stockMinimo": int(d.get("stockMinimo", 0)),
                "cantidadActual": int(d.get("cantidadActual", 0)),
                "estado": d.get("estado", "NORMAL"),
            }
        )
    return resultados


@app.get("/inventario/historial", response_model=List[MovimientoInventarioOut])
def listar_historial_inventario(sedeId: str = Query(..., alias="sedeId")):
    historial_col = get_collection("inventario_historial")
    productos_col = get_collection("productos")

    docs = list(
        historial_col.find({"sedeId": sedeId}).sort("fecha", -1)
    )

    resultados: List[dict[str, Any]] = []
    for d in docs:
        prod = productos_col.find_one({"_id": d.get("productoId")}) or {}
        resultados.append(
            {
                "id": str(d.get("_id")),
                "fecha": d.get("fecha", datetime.utcnow()),
                "tipo": d.get("tipo", "entrada"),
                "producto": prod.get("nombre", d.get("productoId", "")),
                "cantidad": int(d.get("cantidad", 0)),
                "motivo": d.get("motivo"),
                "origen": d.get("sedeOrigenId"),
                "destino": d.get("sedeDestinoId"),
            }
        )

    return resultados


@app.post("/inventario/movimiento", response_model=MovimientoInventarioOut)
def registrar_movimiento_inventario(payload: MovimientoInventarioIn):
    if payload.cantidad <= 0:
        raise HTTPException(status_code=400, detail="La cantidad debe ser mayor a 0")

    productos_col = get_collection("productos")
    historial_col = get_collection("inventario_historial")

    prod = productos_col.find_one({"_id": payload.productoId, "sedeId": payload.sedeId})
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado para esa sede")

    fecha = datetime.utcnow()

    # Insertar en historial
    doc_historial = {
      "fecha": fecha,
      "tipo": payload.tipo,
      "productoId": payload.productoId,
      "sedeId": payload.sedeId,
      "cantidad": payload.cantidad,
      "sedeOrigenId": payload.sedeOrigenId,
      "sedeDestinoId": payload.sedeDestinoId,
      "motivo": payload.motivo,
      "creadoEn": fecha,
    }

    insert_result = historial_col.insert_one(doc_historial)

    # Actualizar cantidad actual del producto
    cantidad_actual = int(prod.get("cantidadActual", 0))
    stock_minimo = int(prod.get("stockMinimo", 0))

    if payload.tipo == "entrada":
        nueva_cantidad = cantidad_actual + payload.cantidad
    elif payload.tipo in {"salida", "transferencia"}:
        nueva_cantidad = max(0, cantidad_actual - payload.cantidad)
    else:
        raise HTTPException(status_code=400, detail="Tipo de movimiento no válido")

    nuevo_estado = "STOCK_BAJO" if nueva_cantidad < stock_minimo else "NORMAL"

    productos_col.update_one(
        {"_id": payload.productoId, "sedeId": payload.sedeId},
        {"$set": {"cantidadActual": nueva_cantidad, "estado": nuevo_estado}},
    )

    return MovimientoInventarioOut(
        id=str(insert_result.inserted_id),
        fecha=fecha,
        tipo=payload.tipo,
        producto=prod.get("nombre", payload.productoId),
        cantidad=payload.cantidad,
        motivo=payload.motivo,
        origen=payload.sedeOrigenId,
        destino=payload.sedeDestinoId,
    )


# PLATOS SERVIDOS


@app.get("/platos/historial", response_model=List[RegistroPlatoOut])
def listar_historial_platos(sedeId: str = Query(..., alias="sedeId")):
    platos_col = get_collection("platos_historial")

    docs = list(platos_col.find({"sedeId": sedeId}).sort("fecha", -1))

    resultados: List[dict[str, Any]] = []
    for d in docs:
        resultados.append(
            {
                "id": str(d.get("_id")),
                "fecha": d.get("fecha", datetime.utcnow()),
                "sedeId": d.get("sedeId"),
                "cargoId": d.get("cargoId"),
                "nombrePlato": d.get("nombrePlato"),
                "cantidadPersonas": int(d.get("cantidadPersonas", 0)),
                "observaciones": d.get("observaciones"),
            }
        )

    return resultados


@app.post("/platos/registro", response_model=RegistroPlatoOut)
def registrar_plato(payload: RegistroPlatoIn):
    if payload.cantidadPersonas <= 0:
        raise HTTPException(status_code=400, detail="La cantidad de personas debe ser mayor a 0")
    platos_col = get_collection("platos_historial")
    productos_col = get_collection("productos")
    historial_col = get_collection("inventario_historial")

    fecha = payload.fecha or datetime.utcnow()

    # Validar stock disponible para cada ingrediente
    for ing in payload.ingredientes:
      if ing.cantidad <= 0:
          raise HTTPException(
              status_code=400,
              detail=f"La cantidad del ingrediente {ing.productoId} debe ser mayor a 0",
          )

      prod = productos_col.find_one({"_id": ing.productoId, "sedeId": payload.sedeId})
      if not prod:
          raise HTTPException(
              status_code=404,
              detail=f"Producto {ing.productoId} no encontrado para esa sede",
          )

      cantidad_actual = int(prod.get("cantidadActual", 0))
      usar = int(ing.cantidad)
      if usar > cantidad_actual:
          nombre = prod.get("nombre", ing.productoId)
          raise HTTPException(
              status_code=400,
              detail=(
                  f"Stock insuficiente para {nombre}. Disponible: {cantidad_actual}, "
                  f"solicitado: {usar}"
              ),
          )

    # Resumen de ingredientes como texto para cumplir el validador actual
    if payload.ingredientes:
        ingredientes_texto = ", ".join(
            f"{ing.productoId} ({ing.cantidad})" for ing in payload.ingredientes
        )
    else:
        ingredientes_texto = None

    doc = {
        "fecha": fecha,
        "sedeId": payload.sedeId,
        # El esquema actual requiere tipoComida string; usamos un valor genérico
        "tipoComida": "OTRO",
        "cargoId": payload.cargoId,
        "nombrePlato": payload.nombrePlato,
        "ingredientes": ingredientes_texto,
        # Guardamos también el detalle estructurado en un campo adicional
        "ingredientesDetalle": [ing.dict() for ing in payload.ingredientes],
        "cantidadPersonas": payload.cantidadPersonas,
        "observaciones": payload.observaciones,
        "creadoEn": datetime.utcnow(),
    }

    result = platos_col.insert_one(doc)

    # Registrar salidas de inventario y actualizar stock por cada ingrediente
    for ing in payload.ingredientes:
        prod = productos_col.find_one({"_id": ing.productoId, "sedeId": payload.sedeId})
        if not prod:
            # Ya validado antes, pero por seguridad
            continue

        cantidad_actual = int(prod.get("cantidadActual", 0))
        stock_minimo = int(prod.get("stockMinimo", 0))
        usar = int(ing.cantidad)

        nueva_cantidad = max(0, cantidad_actual - usar)
        nuevo_estado = "STOCK_BAJO" if nueva_cantidad < stock_minimo else "NORMAL"

        productos_col.update_one(
            {"_id": ing.productoId, "sedeId": payload.sedeId},
            {"$set": {"cantidadActual": nueva_cantidad, "estado": nuevo_estado}},
        )

        historial_col.insert_one(
            {
                "fecha": fecha,
                "tipo": "salida",
                "productoId": ing.productoId,
                "sedeId": payload.sedeId,
                "cantidad": usar,
                "sedeOrigenId": None,
                "sedeDestinoId": None,
                "motivo": f"Uso en plato {payload.nombrePlato}",
                "creadoEn": fecha,
            }
        )

    return RegistroPlatoOut(
        id=str(result.inserted_id),
        fecha=fecha,
        sedeId=payload.sedeId,
        cargoId=payload.cargoId,
        nombrePlato=payload.nombrePlato,
        cantidadPersonas=payload.cantidadPersonas,
        observaciones=payload.observaciones,
    )
