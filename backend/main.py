"""API de FastAPI para la app de Nutrición Hogar Bambi.

Por ahora se enfoca en:
- Inventario (productos + historial de movimientos)
- Platos servidos (historial y registro de nuevos platos)
"""

from __future__ import annotations

from datetime import datetime
import re
from typing import Any, Dict, List, Optional

from bson import ObjectId
from fastapi import BackgroundTasks, FastAPI, HTTPException, Query
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


@app.get("/health")
def health() -> dict[str, str]:
    """Endpoint simple para comprobar que el backend está levantado."""

    return {"status": "ok"}


@app.post("/shutdown")
async def shutdown(background_tasks: BackgroundTasks) -> dict[str, str]:
    """Apaga el servidor.

    Solo se utiliza desde la app de escritorio (localhost).
    """

    import os
    import time

    def _stop() -> None:
        # Pequeña espera para que la respuesta llegue al cliente
        time.sleep(0.5)
        os._exit(0)

    background_tasks.add_task(_stop)
    return {"status": "shutting down"}


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


class ProductoDetailOut(BaseModel):
    id: str
    nombre: str
    categoria: str
    unidad: str
    stockMinBambiEnlace: float
    stockMinBambiII: float
    stockMinBambiIII: float
    stockMinBambiIV: float
    stockMinBambiV: float


class ProductoUpdateIn(BaseModel):
    nombre: Optional[str] = None
    categoria: Optional[str] = None
    unidad: Optional[str] = None
    stockMinBambiEnlace: Optional[float] = None
    stockMinBambiII: Optional[float] = None
    stockMinBambiIII: Optional[float] = None
    stockMinBambiIV: Optional[float] = None
    stockMinBambiV: Optional[float] = None


class ProductoCreateIn(BaseModel):
    nombre: str
    categoria: str
    unidad: str
    stockMinBambiEnlace: float = 0
    stockMinBambiII: float = 0
    stockMinBambiIII: float = 0
    stockMinBambiIV: float = 0
    stockMinBambiV: float = 0


class SedeOut(BaseModel):
    id: str
    nombre: str
    codigo: str
    activa: bool


class MovimientoInventarioIn(BaseModel):
    tipo: str  # entrada | transferencia | ajuste
    productoId: str
    sedeId: str  # sede origen / sede donde se registra el movimiento
    cantidad: int = Field(0, description="Cantidad para entradas; se ignora en transferencias")
    modoTransferencia: Optional[str] = None  # stock_minimo_destino | personalizada
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


class AbastecerStockMinimoIn(BaseModel):
    sedeId: str
    sedeDestinoId: str
    motivo: Optional[str] = None


class AbastecerStockMinimoOut(BaseModel):
    procesados: int
    transferidos: int
    omitidosStockMinimoCero: int
    omitidosSinStockOrigen: int
    omitidosCantidadTransferirCero: int


class AbastecerStockMinimoResumenItem(BaseModel):
    productoId: str
    nombre: str
    unidad: str
    stockMinimoDestino: float
    stockDisponibleOrigen: float
    cantidadTransferir: float


class AbastecerStockMinimoResumenOut(BaseModel):
    sedeId: str
    sedeDestinoId: str
    totalProductosTransferir: int
    totalCantidadTransferir: float
    omitidosStockMinimoCero: int
    omitidosSinStockOrigen: int
    omitidosCantidadTransferirCero: int
    items: List[AbastecerStockMinimoResumenItem]


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


class CargoOut(BaseModel):
    id: str
    nombre: str
    tipo: int
    sedes: List[str]
    observaciones: Optional[str] = None


class CargoBaseIn(BaseModel):
    nombre: str
    tipo: int = 1
    sedes: List[str] = Field(default_factory=list)
    observaciones: Optional[str] = None


class CargoCreateIn(CargoBaseIn):
    pass


class CargoUpdateIn(CargoBaseIn):
    pass


class TipoPlatoOut(BaseModel):
    id: str
    nombre: str
    activo: bool


class RegistroCargoComidaIn(BaseModel):
    cargoId: str
    cantidadPersonas: int


class RegistroComidaIn(BaseModel):
    fechaRegistro: datetime
    sedeId: str
    tipoComidaId: str
    registros: List[RegistroCargoComidaIn]


class RegistroComidaResultado(BaseModel):
    insertados: int


class RegistroComidaOut(BaseModel):
    id: str
    fecha: datetime
    sedeId: str
    tipoComida: str
    cargoId: str
    cantidadPersonas: int
    observaciones: Optional[str] = None
    registradoEl: Optional[datetime] = None
    creadoEl: Optional[datetime] = None


class RegistroComidaUpdateIn(BaseModel):
    fecha: datetime
    sedeId: str
    tipoComida: str
    cargoId: str
    cantidadPersonas: int
    observaciones: Optional[str] = None


class CategoriaPlatosSede(BaseModel):
    sedeId: str
    cantidad: int


class CategoriaPlatosResumen(BaseModel):
    codigo: str
    nombre: str
    total: int
    porSede: List[CategoriaPlatosSede]


class ResumenPlatosServidosOut(BaseModel):
    desde: datetime
    hasta: datetime
    categorias: List[CategoriaPlatosResumen]


class TipoPlatoSedeResumen(BaseModel):
    sedeId: str
    cantidad: int


class TipoPlatoResumen(BaseModel):
    codigo: str
    nombre: str
    total: int
    porSede: List[TipoPlatoSedeResumen]


class TotalPlatosPorSede(BaseModel):
    sedeId: str
    cantidad: int


class ResumenPlatosPorTipoOut(BaseModel):
    desde: datetime
    hasta: datetime
    tipos: List[TipoPlatoResumen]
    totalGeneral: int
    totalPorSede: List[TotalPlatosPorSede]


class TipoPlatoCategoriaSedeResumen(BaseModel):
    sedeId: str
    cantidad: int


class TipoPlatoCategoriaResumen(BaseModel):
    codigo: str
    nombre: str
    total: int
    porSede: List[TipoPlatoCategoriaSedeResumen]


class TipoPlatoConCategoriasResumen(BaseModel):
    codigo: str
    nombre: str
    categorias: List[TipoPlatoCategoriaResumen]


class ResumenPlatosPorTipoYCargoOut(BaseModel):
    desde: datetime
    hasta: datetime
    tipos: List[TipoPlatoConCategoriasResumen]


# ---------
# ENDPOINTS
# ---------

# SEDES


@app.get("/sedes", response_model=List[SedeOut])
def listar_sedes(activa: Optional[bool] = Query(None, alias="activa")):
    sedes_col = get_collection("sedes")

    query: Dict[str, Any] = {}
    if activa is True:
        query["activa"] = 1
    elif activa is False:
        query["activa"] = 0

    docs = list(sedes_col.find(query).sort("nombre", 1))

    resultados: List[dict[str, Any]] = []
    for d in docs:
        resultados.append(
            {
                "id": d.get("_id", ""),
                "nombre": d.get("nombre", ""),
                "codigo": d.get("codigo", ""),
                "activa": bool(d.get("activa", 1)),
            }
        )

    return resultados


@app.get("/tipos-platos", response_model=List[TipoPlatoOut])
def listar_tipos_platos() -> List[TipoPlatoOut]:
    tipos_col = get_collection("tipos_platos")

    docs = list(tipos_col.find({}).sort("nombre", 1))

    resultados: List[dict[str, Any]] = []
    for d in docs:
        activo_val = d.get("activo", 1)
        resultados.append(
            {
                "id": d.get("_id", ""),
                "nombre": d.get("nombre", ""),
                "activo": bool(activo_val),
            }
        )

    return resultados


@app.get("/cargos", response_model=List[CargoOut])
def listar_cargos() -> List[CargoOut]:
    cargos_col = get_collection("cargos")

    # Solo devolver cargos activos (tipo != 0)
    docs = list(cargos_col.find({"tipo": {"$ne": 0}}).sort("nombre", 1))

    resultados: List[dict[str, Any]] = []
    for d in docs:
        sedes = d.get("sedes") or []
        if not isinstance(sedes, list):
            sedes = [sedes]

        resultados.append(
            {
                "id": d.get("_id", ""),
                "nombre": d.get("nombre", ""),
                "tipo": int(d.get("tipo", 0)),
                "sedes": [str(s) for s in sedes],
                "observaciones": d.get("observaciones"),
            }
        )

    return resultados


@app.post("/cargos", response_model=CargoOut)
def crear_cargo(payload: CargoCreateIn) -> CargoOut:
    cargos_col = get_collection("cargos")

    # ID derivado del nombre: mayúsculas y espacios como "_"
    nombre_limpio = " ".join(payload.nombre.strip().split())
    cargo_id = nombre_limpio.upper().replace(" ", "_")

    existente = cargos_col.find_one({"_id": cargo_id})
    if existente:
        raise HTTPException(status_code=400, detail="Ya existe un cargo con ese nombre")

    doc = {
        "_id": cargo_id,
        "nombre": payload.nombre,
        "tipo": payload.tipo,
        "sedes": payload.sedes,
        "observaciones": payload.observaciones,
    }

    cargos_col.insert_one(doc)

    return CargoOut(
        id=cargo_id,
        nombre=payload.nombre,
        tipo=payload.tipo,
        sedes=payload.sedes,
        observaciones=payload.observaciones,
    )


@app.put("/cargos/{cargo_id}", response_model=CargoOut)
def actualizar_cargo(cargo_id: str, payload: CargoUpdateIn) -> CargoOut:
    cargos_col = get_collection("cargos")

    update_doc = {
        "nombre": payload.nombre,
        "tipo": payload.tipo,
        "sedes": payload.sedes,
        "observaciones": payload.observaciones,
    }

    result = cargos_col.update_one({"_id": cargo_id}, {"$set": update_doc})

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Cargo no encontrado")

    doc = cargos_col.find_one({"_id": cargo_id}) or update_doc

    sedes = doc.get("sedes") or []
    if not isinstance(sedes, list):
        sedes = [sedes]

    return CargoOut(
        id=cargo_id,
        nombre=doc.get("nombre", payload.nombre),
        tipo=int(doc.get("tipo", payload.tipo)),
        sedes=[str(s) for s in sedes],
        observaciones=doc.get("observaciones", payload.observaciones),
    )


# INVENTARIO


def _stock_min_for_sede(prod: Dict[str, Any], sede_id: str) -> float:
    """Obtiene el stock mínimo de un producto para una sede dada.

    Soporta tanto los IDs nuevos (BAMBI_*) como los antiguos (CASA_*).
    """

    mapping = {
        # Nuevos IDs de sedes
        "BAMBI_ENLACE": "stockMinBambiEnlace",
        "BAMBI_II": "stockMinBambiII",
        "BAMBI_III": "stockMinBambiIII",
        "BAMBI_IV": "stockMinBambiIV",
        "BAMBI_V": "stockMinBambiV",
        # Compatibilidad con nombres antiguos
        "CASA_PRINCIPAL": "stockMinBambiEnlace",
        "CASA_ANGELES": "stockMinBambiII",
        "CASA_ESPERANZA": "stockMinBambiIII",
        "CASA_ESTRELLAS": "stockMinBambiIV",
        "CASA_SUENOS": "stockMinBambiV",
    }

    field = mapping.get(sede_id)
    if not field:
        return 0.0

    value = prod.get(field, 0)
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _producto_id_desde_nombre(nombre: str) -> str:
    base = " ".join(nombre.strip().split())
    base = re.sub(r"\s+", "_", base)
    base = re.sub(r"[^A-Za-z0-9_]", "", base)
    return base.upper()


@app.get("/inventario/productos", response_model=List[ProductoOut])
def listar_productos(sedeId: str = Query(..., alias="sedeId")):
    productos_col = get_collection("productos")
    inventario_col = get_collection("inventario_sedes")

    # Todos los productos (catálogo completo)
    productos = list(productos_col.find({}))
    # Inventario actual de la sede
    inventario_docs = {
        d.get("productoId"): d for d in inventario_col.find({"sedeId": sedeId})
    }

    resultados: List[dict[str, Any]] = []
    for p in productos:
        prod_id = p.get("_id")
        inv = inventario_docs.get(prod_id, {})

        cantidad_actual = float(inv.get("cantidadActual", 0))
        stock_min = _stock_min_for_sede(p, sedeId)

        # Estado base desde inventario, pero forzamos STOCK_BAJO si está por debajo del mínimo
        estado = inv.get("estado", "NORMAL")
        if stock_min > 0 and cantidad_actual < stock_min:
            estado = "STOCK_BAJO"

        resultados.append(
            {
                "id": prod_id,
                "nombre": p.get("nombre", ""),
                "categoria": p.get("categoria", ""),
                "unidad": p.get("unidad", ""),
                "stockMinimo": int(stock_min),
                "cantidadActual": int(cantidad_actual),
                "estado": estado,
            }
        )

    return resultados


@app.get("/inventario/productos/{producto_id}", response_model=ProductoDetailOut)
def obtener_detalle_producto(producto_id: str):
    """Obtiene todos los detalles de un producto, incluyendo stock mínimo de todas las sedes."""
    productos_col = get_collection("productos")

    prod = productos_col.find_one({"_id": producto_id})
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    return ProductoDetailOut(
        id=prod.get("_id", ""),
        nombre=prod.get("nombre", ""),
        categoria=prod.get("categoria", ""),
        unidad=prod.get("unidad", ""),
        stockMinBambiEnlace=float(prod.get("stockMinBambiEnlace", 0)),
        stockMinBambiII=float(prod.get("stockMinBambiII", 0)),
        stockMinBambiIII=float(prod.get("stockMinBambiIII", 0)),
        stockMinBambiIV=float(prod.get("stockMinBambiIV", 0)),
        stockMinBambiV=float(prod.get("stockMinBambiV", 0)),
    )


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


@app.put("/inventario/productos/{producto_id}", response_model=ProductoOut)
def actualizar_producto(producto_id: str, payload: ProductoUpdateIn, sedeId: str = Query(..., alias="sedeId")):
    """Actualiza los detalles de un producto (nombre, categoría, unidad, stock mínimo por sede)."""
    productos_col = get_collection("productos")
    inventario_col = get_collection("inventario_sedes")

    # Validar que el producto existe
    prod = productos_col.find_one({"_id": producto_id})
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    # Construir el documento de actualización
    update_doc = {}
    if payload.nombre is not None:
        update_doc["nombre"] = payload.nombre
    if payload.categoria is not None:
        update_doc["categoria"] = payload.categoria
    if payload.unidad is not None:
        update_doc["unidad"] = payload.unidad
    if payload.stockMinBambiEnlace is not None:
        update_doc["stockMinBambiEnlace"] = payload.stockMinBambiEnlace
    if payload.stockMinBambiII is not None:
        update_doc["stockMinBambiII"] = payload.stockMinBambiII
    if payload.stockMinBambiIII is not None:
        update_doc["stockMinBambiIII"] = payload.stockMinBambiIII
    if payload.stockMinBambiIV is not None:
        update_doc["stockMinBambiIV"] = payload.stockMinBambiIV
    if payload.stockMinBambiV is not None:
        update_doc["stockMinBambiV"] = payload.stockMinBambiV

    # Actualizar en la BD
    productos_col.update_one({"_id": producto_id}, {"$set": update_doc})

    # Recargar producto actualizado
    prod = productos_col.find_one({"_id": producto_id})
    prod.update(update_doc)

    # Obtener inventario actual para la sede
    inv = inventario_col.find_one({"sedeId": sedeId, "productoId": producto_id}) or {}
    cantidad_actual = float(inv.get("cantidadActual", 0))
    stock_min = _stock_min_for_sede(prod, sedeId)

    estado = inv.get("estado", "NORMAL")
    if stock_min > 0 and cantidad_actual < stock_min:
        estado = "STOCK_BAJO"

    return ProductoOut(
        id=producto_id,
        nombre=prod.get("nombre", ""),
        categoria=prod.get("categoria", ""),
        unidad=prod.get("unidad", ""),
        stockMinimo=int(stock_min),
        cantidadActual=int(cantidad_actual),
        estado=estado,
    )


@app.post("/inventario/productos", response_model=ProductoDetailOut)
def crear_producto(payload: ProductoCreateIn):
    productos_col = get_collection("productos")

    nombre_limpio = " ".join(payload.nombre.strip().split())
    producto_id = _producto_id_desde_nombre(nombre_limpio)
    if not producto_id:
        raise HTTPException(status_code=400, detail="No se pudo generar ID desde el nombre")

    existente = productos_col.find_one({"_id": producto_id})
    if existente:
        raise HTTPException(status_code=400, detail="Ya existe un producto con ese ID")

    doc = {
        "_id": producto_id,
        "nombre": nombre_limpio,
        "categoria": payload.categoria.strip(),
        "unidad": payload.unidad.strip(),
        "stockMinBambiEnlace": float(payload.stockMinBambiEnlace),
        "stockMinBambiII": float(payload.stockMinBambiII),
        "stockMinBambiIII": float(payload.stockMinBambiIII),
        "stockMinBambiIV": float(payload.stockMinBambiIV),
        "stockMinBambiV": float(payload.stockMinBambiV),
    }

    productos_col.insert_one(doc)

    return ProductoDetailOut(
        id=doc["_id"],
        nombre=doc["nombre"],
        categoria=doc["categoria"],
        unidad=doc["unidad"],
        stockMinBambiEnlace=doc["stockMinBambiEnlace"],
        stockMinBambiII=doc["stockMinBambiII"],
        stockMinBambiIII=doc["stockMinBambiIII"],
        stockMinBambiIV=doc["stockMinBambiIV"],
        stockMinBambiV=doc["stockMinBambiV"],
    )


@app.post("/inventario/movimiento", response_model=MovimientoInventarioOut)
def registrar_movimiento_inventario(payload: MovimientoInventarioIn):
    productos_col = get_collection("productos")
    inventario_col = get_collection("inventario_sedes")
    historial_col = get_collection("inventario_historial")

    prod = productos_col.find_one({"_id": payload.productoId})
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    fecha = datetime.utcnow()

    # ENTRADA: suma cantidad al inventario de la sede actual
    if payload.tipo == "entrada":
        if payload.cantidad <= 0:
            raise HTTPException(status_code=400, detail="La cantidad debe ser mayor a 0 para una entrada")

        inv_doc = inventario_col.find_one({
            "sedeId": payload.sedeId,
            "productoId": payload.productoId,
        }) or {}

        cantidad_actual = float(inv_doc.get("cantidadActual", 0))
        nueva_cantidad = cantidad_actual + payload.cantidad

        stock_min = _stock_min_for_sede(prod, payload.sedeId)
        nuevo_estado = "STOCK_BAJO" if stock_min > 0 and nueva_cantidad < stock_min else "NORMAL"

        inventario_col.update_one(
            {"sedeId": payload.sedeId, "productoId": payload.productoId},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad,
                    "estado": nuevo_estado,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        doc_historial = {
            "fecha": fecha,
            "tipo": "entrada",
            "productoId": payload.productoId,
            "sedeId": payload.sedeId,
            "cantidad": float(payload.cantidad),
            "sedeOrigenId": None,
            "sedeDestinoId": None,
            "motivo": payload.motivo,
            "creadoEn": fecha,
        }

        insert_result = historial_col.insert_one(doc_historial)

        return MovimientoInventarioOut(
            id=str(insert_result.inserted_id),
            fecha=fecha,
            tipo="entrada",
            producto=prod.get("nombre", payload.productoId),
            cantidad=payload.cantidad,
            motivo=payload.motivo,
            origen=None,
            destino=None,
        )

    # TRANSFERENCIA A OTRA SEDE: calcular cantidad a transferir según stock mínimo de la sede destino
    if payload.tipo == "transferencia":
        if not payload.sedeDestinoId:
            raise HTTPException(status_code=400, detail="Debe indicar la sede destino para la transferencia")

        sede_origen = payload.sedeId
        sede_destino = payload.sedeDestinoId

        if sede_origen == sede_destino:
            raise HTTPException(status_code=400, detail="La sede origen y destino no pueden ser la misma")

        inv_origen = inventario_col.find_one({
            "sedeId": sede_origen,
            "productoId": payload.productoId,
        }) or {}
        cantidad_origen = float(inv_origen.get("cantidadActual", 0))

        if cantidad_origen <= 0:
            raise HTTPException(
                status_code=400,
                detail="No hay inventario disponible en la sede origen para este producto",
            )

        modo_transferencia = payload.modoTransferencia or "stock_minimo_destino"

        inv_destino = inventario_col.find_one({
            "sedeId": sede_destino,
            "productoId": payload.productoId,
        }) or {}
        cantidad_destino = float(inv_destino.get("cantidadActual", 0))

        stock_min_destino = _stock_min_for_sede(prod, sede_destino)

        if modo_transferencia == "personalizada":
            if payload.cantidad <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="La cantidad personalizada debe ser mayor a 0",
                )
            if float(payload.cantidad) > cantidad_origen:
                raise HTTPException(
                    status_code=400,
                    detail="No hay suficiente stock en la sede origen para la cantidad solicitada",
                )
            cantidad_transferir = float(payload.cantidad)
        else:
            # Modo por defecto: abastecer al stock mínimo de destino según faltante
            if stock_min_destino <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="No hay stock mínimo configurado para la sede destino",
                )

            faltante = stock_min_destino - cantidad_destino
            if faltante <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="La sede destino ya cumple o supera el stock mínimo para este producto",
                )

            cantidad_transferir = min(faltante, cantidad_origen)

        if cantidad_transferir <= 0:
            raise HTTPException(
                status_code=400,
                detail="La cantidad a transferir calculada es 0",
            )

        nueva_cantidad_origen = cantidad_origen - cantidad_transferir
        stock_min_origen = _stock_min_for_sede(prod, sede_origen)
        nuevo_estado_origen = (
            "STOCK_BAJO" if stock_min_origen > 0 and nueva_cantidad_origen < stock_min_origen else "NORMAL"
        )

        inventario_col.update_one(
            {"sedeId": sede_origen, "productoId": payload.productoId},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad_origen,
                    "estado": nuevo_estado_origen,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        # Sumar la cantidad transferida al inventario de la sede destino
        nueva_cantidad_destino = cantidad_destino + cantidad_transferir
        nuevo_estado_destino = (
            "STOCK_BAJO" if stock_min_destino > 0 and nueva_cantidad_destino < stock_min_destino else "NORMAL"
        )

        inventario_col.update_one(
            {"sedeId": sede_destino, "productoId": payload.productoId},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad_destino,
                    "estado": nuevo_estado_destino,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        # Registrar como SALIDA en sede origen
        doc_salida = {
            "fecha": fecha,
            "tipo": "salida",
            "productoId": payload.productoId,
            "sedeId": sede_origen,
            "cantidad": float(cantidad_transferir),
            "sedeOrigenId": sede_origen,
            "sedeDestinoId": sede_destino,
            "motivo": payload.motivo,
            "creadoEn": fecha,
        }

        insert_salida = historial_col.insert_one(doc_salida)

        # Registrar como ENTRADA en sede destino
        doc_entrada = {
            "fecha": fecha,
            "tipo": "entrada",
            "productoId": payload.productoId,
            "sedeId": sede_destino,
            "cantidad": float(cantidad_transferir),
            "sedeOrigenId": sede_origen,
            "sedeDestinoId": sede_destino,
            "motivo": payload.motivo,
            "creadoEn": fecha,
        }

        historial_col.insert_one(doc_entrada)

        # Devolvemos la operación global como "transferencia"
        return MovimientoInventarioOut(
            id=str(insert_salida.inserted_id),
            fecha=fecha,
            tipo="transferencia",
            producto=prod.get("nombre", payload.productoId),
            cantidad=int(cantidad_transferir),
            motivo=payload.motivo,
            origen=sede_origen,
            destino=sede_destino,
        )

    # AJUSTE: ajustar inventario de una sede a una cantidad reportada
    if payload.tipo == "ajuste":
        if payload.cantidad < 0:
            raise HTTPException(status_code=400, detail="La cantidad de ajuste debe ser mayor o igual a 0")

        inv_doc = inventario_col.find_one({
            "sedeId": payload.sedeId,
            "productoId": payload.productoId,
        }) or {}

        cantidad_actual = float(inv_doc.get("cantidadActual", 0))
        nueva_cantidad = float(payload.cantidad)

        if nueva_cantidad > cantidad_actual:
            raise HTTPException(
                status_code=400,
                detail=(
                    "El reporte de ajuste excede la cantidad actual en inventario. "
                    f"Actual: {cantidad_actual}, reportado: {nueva_cantidad}"
                ),
            )

        cantidad_retirar = cantidad_actual - nueva_cantidad

        stock_min = _stock_min_for_sede(prod, payload.sedeId)
        nuevo_estado = "STOCK_BAJO" if stock_min > 0 and nueva_cantidad < stock_min else "NORMAL"

        inventario_col.update_one(
            {"sedeId": payload.sedeId, "productoId": payload.productoId},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad,
                    "estado": nuevo_estado,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        doc_historial = {
            "fecha": fecha,
            "tipo": "ajuste",
            "productoId": payload.productoId,
            "sedeId": payload.sedeId,
            # Guardamos cuánto se retiró del inventario para llegar al valor reportado
            "cantidad": float(cantidad_retirar),
            "sedeOrigenId": None,
            "sedeDestinoId": None,
            "motivo": payload.motivo,
            "creadoEn": fecha,
        }

        insert_result = historial_col.insert_one(doc_historial)

        return MovimientoInventarioOut(
            id=str(insert_result.inserted_id),
            fecha=fecha,
            tipo="ajuste",
            producto=prod.get("nombre", payload.productoId),
            cantidad=int(cantidad_retirar),
            motivo=payload.motivo,
            origen=None,
            destino=None,
        )

    raise HTTPException(status_code=400, detail="Tipo de movimiento no válido (solo entrada, transferencia o ajuste)")


@app.post("/inventario/abastecer-stock-minimo", response_model=AbastecerStockMinimoOut)
def abastecer_stock_minimo(payload: AbastecerStockMinimoIn) -> AbastecerStockMinimoOut:
    """Transfiere productos a una sede destino usando su stock mínimo configurado.

    Reglas:
    - Omite productos cuyo stock mínimo en destino sea 0.
    - La cantidad a transferir por producto es el stock mínimo de la sede destino.
    - Si origen no tiene suficiente, transfiere lo disponible.
    """

    sede_origen = payload.sedeId
    sede_destino = payload.sedeDestinoId
    if sede_origen == sede_destino:
        raise HTTPException(status_code=400, detail="La sede origen y destino no pueden ser la misma")

    productos_col = get_collection("productos")
    inventario_col = get_collection("inventario_sedes")
    historial_col = get_collection("inventario_historial")

    fecha = datetime.utcnow()
    procesados = 0
    transferidos = 0
    omitidos_stock_minimo_cero = 0
    omitidos_sin_stock_origen = 0
    omitidos_cantidad_transferir_cero = 0

    productos = list(productos_col.find({}))
    for prod in productos:
        producto_id = str(prod.get("_id", ""))
        if not producto_id:
            continue

        stock_min_destino = _stock_min_for_sede(prod, sede_destino)
        if stock_min_destino <= 0:
            omitidos_stock_minimo_cero += 1
            continue

        inv_origen = inventario_col.find_one({"sedeId": sede_origen, "productoId": producto_id}) or {}
        cantidad_origen = float(inv_origen.get("cantidadActual", 0))
        if cantidad_origen <= 0:
            omitidos_sin_stock_origen += 1
            continue

        cantidad_transferir = min(float(stock_min_destino), cantidad_origen)
        if cantidad_transferir <= 0:
            omitidos_cantidad_transferir_cero += 1
            continue

        procesados += 1

        nueva_cantidad_origen = max(0.0, cantidad_origen - cantidad_transferir)
        stock_min_origen = _stock_min_for_sede(prod, sede_origen)
        nuevo_estado_origen = (
            "STOCK_BAJO" if stock_min_origen > 0 and nueva_cantidad_origen < stock_min_origen else "NORMAL"
        )

        inventario_col.update_one(
            {"sedeId": sede_origen, "productoId": producto_id},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad_origen,
                    "estado": nuevo_estado_origen,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        inv_destino = inventario_col.find_one({"sedeId": sede_destino, "productoId": producto_id}) or {}
        cantidad_destino = float(inv_destino.get("cantidadActual", 0))
        nueva_cantidad_destino = cantidad_destino + cantidad_transferir
        nuevo_estado_destino = (
            "STOCK_BAJO" if stock_min_destino > 0 and nueva_cantidad_destino < stock_min_destino else "NORMAL"
        )

        inventario_col.update_one(
            {"sedeId": sede_destino, "productoId": producto_id},
            {
                "$set": {
                    "cantidadActual": nueva_cantidad_destino,
                    "estado": nuevo_estado_destino,
                    "actualizadoEn": fecha,
                }
            },
            upsert=True,
        )

        motivo_base = payload.motivo or "Abastecer stock mínimo de sede destino"

        historial_col.insert_one(
            {
                "fecha": fecha,
                "tipo": "salida",
                "productoId": producto_id,
                "sedeId": sede_origen,
                "cantidad": float(cantidad_transferir),
                "sedeOrigenId": sede_origen,
                "sedeDestinoId": sede_destino,
                "motivo": motivo_base,
                "creadoEn": fecha,
            }
        )

        historial_col.insert_one(
            {
                "fecha": fecha,
                "tipo": "entrada",
                "productoId": producto_id,
                "sedeId": sede_destino,
                "cantidad": float(cantidad_transferir),
                "sedeOrigenId": sede_origen,
                "sedeDestinoId": sede_destino,
                "motivo": motivo_base,
                "creadoEn": fecha,
            }
        )

        transferidos += 1

    return AbastecerStockMinimoOut(
        procesados=procesados,
        transferidos=transferidos,
        omitidosStockMinimoCero=omitidos_stock_minimo_cero,
        omitidosSinStockOrigen=omitidos_sin_stock_origen,
        omitidosCantidadTransferirCero=omitidos_cantidad_transferir_cero,
    )


@app.post(
    "/inventario/abastecer-stock-minimo/resumen",
    response_model=AbastecerStockMinimoResumenOut,
)
def resumen_abastecer_stock_minimo(payload: AbastecerStockMinimoIn) -> AbastecerStockMinimoResumenOut:
    """Devuelve el resumen de cantidades a transferir sin ejecutar movimientos."""

    sede_origen = payload.sedeId
    sede_destino = payload.sedeDestinoId
    if sede_origen == sede_destino:
        raise HTTPException(status_code=400, detail="La sede origen y destino no pueden ser la misma")

    productos_col = get_collection("productos")
    inventario_col = get_collection("inventario_sedes")

    omitidos_stock_minimo_cero = 0
    omitidos_sin_stock_origen = 0
    omitidos_cantidad_transferir_cero = 0
    items: List[AbastecerStockMinimoResumenItem] = []

    productos = list(productos_col.find({}))
    for prod in productos:
        producto_id = str(prod.get("_id", ""))
        if not producto_id:
            continue

        stock_min_destino = _stock_min_for_sede(prod, sede_destino)
        if stock_min_destino <= 0:
            omitidos_stock_minimo_cero += 1
            continue

        inv_origen = inventario_col.find_one({"sedeId": sede_origen, "productoId": producto_id}) or {}
        cantidad_origen = float(inv_origen.get("cantidadActual", 0))
        if cantidad_origen <= 0:
            omitidos_sin_stock_origen += 1
            continue

        cantidad_transferir = min(float(stock_min_destino), cantidad_origen)
        if cantidad_transferir <= 0:
            omitidos_cantidad_transferir_cero += 1
            continue

        items.append(
            AbastecerStockMinimoResumenItem(
                productoId=producto_id,
                nombre=str(prod.get("nombre", producto_id)),
                unidad=str(prod.get("unidad", "u")),
                stockMinimoDestino=float(stock_min_destino),
                stockDisponibleOrigen=float(cantidad_origen),
                cantidadTransferir=float(cantidad_transferir),
            )
        )

    total_cantidad = sum(i.cantidadTransferir for i in items)

    return AbastecerStockMinimoResumenOut(
        sedeId=sede_origen,
        sedeDestinoId=sede_destino,
        totalProductosTransferir=len(items),
        totalCantidadTransferir=float(total_cantidad),
        omitidosStockMinimoCero=omitidos_stock_minimo_cero,
        omitidosSinStockOrigen=omitidos_sin_stock_origen,
        omitidosCantidadTransferirCero=omitidos_cantidad_transferir_cero,
        items=items,
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
                "cantidad": float(usar),
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


@app.post("/platos/registrar-comida", response_model=RegistroComidaResultado)
def registrar_comida_por_cargos(payload: RegistroComidaIn) -> RegistroComidaResultado:
    """Registra en platos_historial la cantidad de personas que comieron por cargo.

    Crea un documento por cada cargo con cantidadPersonas > 0.
    - fechaRegistro: fecha indicada por el usuario (día del servicio).
    - creadoEl: fecha/hora actual del sistema.
    - registradoEl: misma fecha que fechaRegistro para trazabilidad.
    """

    if not payload.registros:
        raise HTTPException(status_code=400, detail="Debe incluir al menos un cargo")

    registros_validos = [
        r for r in payload.registros if r.cantidadPersonas and r.cantidadPersonas > 0
    ]
    if not registros_validos:
        raise HTTPException(
            status_code=400,
            detail="Debe haber al menos un cargo con cantidad de personas mayor a 0",
        )

    platos_col = get_collection("platos_historial")
    tipos_col = get_collection("tipos_platos")

    # Validar que el tipo de plato exista
    tipo = tipos_col.find_one({"_id": payload.tipoComidaId})
    if not tipo:
        raise HTTPException(status_code=400, detail="Tipo de comida no válido")

    fecha_registro = payload.fechaRegistro
    ahora = datetime.utcnow()

    documentos: List[Dict[str, Any]] = []
    for r in registros_validos:
        if r.cantidadPersonas <= 0:
            continue

        documentos.append(
            {
                "fecha": fecha_registro,
                "sedeId": payload.sedeId,
                "tipoComida": payload.tipoComidaId,
                "cargoId": r.cargoId,
                "cantidadPersonas": int(r.cantidadPersonas),
                "observaciones": None,
                "registradoEl": fecha_registro,
                "creadoEl": ahora,
            }
        )

    if not documentos:
        raise HTTPException(
            status_code=400,
            detail="No hay registros válidos para guardar",
        )

    result = platos_col.insert_many(documentos)

    return RegistroComidaResultado(insertados=len(result.inserted_ids))


@app.get("/platos/registros-comida", response_model=List[RegistroComidaOut])
def listar_registros_comida(
    sedeId: Optional[str] = Query(None, alias="sedeId"),
    limit: int = Query(100, ge=1, le=500),
) -> List[RegistroComidaOut]:
    """Lista registros de comida para edición.

    Solo incluye documentos del flujo "registrar-comida" que tienen tipoComida.
    """

    platos_col = get_collection("platos_historial")

    query: Dict[str, Any] = {"tipoComida": {"$exists": True}}
    if sedeId:
        query["sedeId"] = sedeId

    docs = list(platos_col.find(query).sort("fecha", -1).limit(limit))

    resultados: List[RegistroComidaOut] = []
    for d in docs:
        fecha = d.get("fecha") or d.get("registradoEl") or d.get("creadoEl") or datetime.utcnow()
        resultados.append(
            RegistroComidaOut(
                id=str(d.get("_id")),
                fecha=fecha,
                sedeId=str(d.get("sedeId", "")),
                tipoComida=str(d.get("tipoComida", "")),
                cargoId=str(d.get("cargoId", "")),
                cantidadPersonas=int(d.get("cantidadPersonas", 0)),
                observaciones=d.get("observaciones"),
                registradoEl=d.get("registradoEl"),
                creadoEl=d.get("creadoEl"),
            )
        )

    return resultados


@app.put("/platos/registros-comida/{registro_id}", response_model=RegistroComidaOut)
def actualizar_registro_comida(registro_id: str, payload: RegistroComidaUpdateIn) -> RegistroComidaOut:
    if payload.cantidadPersonas <= 0:
        raise HTTPException(status_code=400, detail="La cantidad de personas debe ser mayor a 0")

    try:
        mongo_id = ObjectId(registro_id)
    except Exception:
        raise HTTPException(status_code=400, detail="ID de registro inválido")

    platos_col = get_collection("platos_historial")
    tipos_col = get_collection("tipos_platos")
    cargos_col = get_collection("cargos")
    sedes_col = get_collection("sedes")

    existente = platos_col.find_one({"_id": mongo_id})
    if not existente:
        raise HTTPException(status_code=404, detail="Registro no encontrado")

    if not tipos_col.find_one({"_id": payload.tipoComida}):
        raise HTTPException(status_code=400, detail="Tipo de comida no válido")

    if not cargos_col.find_one({"_id": payload.cargoId}):
        raise HTTPException(status_code=400, detail="Cargo no válido")

    if not sedes_col.find_one({"_id": payload.sedeId}):
        raise HTTPException(status_code=400, detail="Sede no válida")

    update_doc = {
        "fecha": payload.fecha,
        "sedeId": payload.sedeId,
        "tipoComida": payload.tipoComida,
        "cargoId": payload.cargoId,
        "cantidadPersonas": int(payload.cantidadPersonas),
        "observaciones": payload.observaciones,
        "registradoEl": payload.fecha,
    }

    platos_col.update_one({"_id": mongo_id}, {"$set": update_doc})

    actualizado = platos_col.find_one({"_id": mongo_id})
    if not actualizado:
        raise HTTPException(status_code=404, detail="Registro no encontrado luego de actualizar")

    fecha = (
        actualizado.get("fecha")
        or actualizado.get("registradoEl")
        or actualizado.get("creadoEl")
        or datetime.utcnow()
    )

    return RegistroComidaOut(
        id=str(actualizado.get("_id")),
        fecha=fecha,
        sedeId=str(actualizado.get("sedeId", "")),
        tipoComida=str(actualizado.get("tipoComida", "")),
        cargoId=str(actualizado.get("cargoId", "")),
        cantidadPersonas=int(actualizado.get("cantidadPersonas", 0)),
        observaciones=actualizado.get("observaciones"),
        registradoEl=actualizado.get("registradoEl"),
        creadoEl=actualizado.get("creadoEl"),
    )


@app.delete("/platos/registros-comida/{registro_id}")
def eliminar_registro_comida(registro_id: str) -> Dict[str, Any]:
    try:
        mongo_id = ObjectId(registro_id)
    except Exception:
        raise HTTPException(status_code=400, detail="ID de registro inválido")

    platos_col = get_collection("platos_historial")
    result = platos_col.delete_one({"_id": mongo_id})

    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Registro no encontrado")

    return {"deleted": True, "id": registro_id}


def _categoria_para_cargo(cargo_id: str, tipo: int | None) -> tuple[Optional[str], Optional[str]]:
    """Devuelve (codigo, nombre) de categoría para un cargo.

    - NNA -> Niños
    - IDs que comienzan por "TIAS" -> Tías
    - tipo == 2 -> Personas Rendición
    - tipo == 1 -> Personas no Rendición
    """

    if cargo_id == "NNA":
        return "NINOS", "Niños"
    if cargo_id.startswith("TIAS"):
        return "TIAS", "Tías"
    if tipo == 2:
        return "ADULTOS_IMPORTANTES", "Personas Rendición"
    if tipo == 1:
        return "ADULTOS_SECUNDARIOS", "Personas no Rendición"
    return None, None


@app.get("/reportes/platos-servidos", response_model=ResumenPlatosServidosOut)
def resumen_platos_servidos(
    desde: datetime = Query(..., alias="desde"),
    hasta: datetime = Query(..., alias="hasta"),
) -> ResumenPlatosServidosOut:
    """Resumen de platos servidos por categoría y por sede en un rango de fechas."""

    if hasta < desde:
        raise HTTPException(status_code=400, detail="La fecha 'hasta' no puede ser menor que 'desde'")

    platos_col = get_collection("platos_historial")
    cargos_col = get_collection("cargos")

    # Mapa de cargos para conocer su tipo
    cargos_docs = list(cargos_col.find({}))
    cargos_info: dict[str, int] = {}
    for c in cargos_docs:
        cid = c.get("_id")
        if not cid:
            continue
        try:
            cargos_info[str(cid)] = int(c.get("tipo", 1))
        except (TypeError, ValueError):
            cargos_info[str(cid)] = 1

    # Inicializar acumuladores
    totales: dict[str, int] = {
        "NINOS": 0,
        "TIAS": 0,
        "ADULTOS_IMPORTANTES": 0,
        "ADULTOS_SECUNDARIOS": 0,
    }
    por_sede: dict[str, dict[str, int]] = {
        "NINOS": {},
        "TIAS": {},
        "ADULTOS_IMPORTANTES": {},
        "ADULTOS_SECUNDARIOS": {},
    }

    # Buscar registros de platos en el rango
    docs = list(
        platos_col.find({"fecha": {"$gte": desde, "$lte": hasta}})
    )

    for d in docs:
        cargo_id = str(d.get("cargoId", ""))
        sede_id = str(d.get("sedeId", ""))
        try:
            cantidad = int(d.get("cantidadPersonas", 0))
        except (TypeError, ValueError):
            continue
        if not cargo_id or not sede_id or cantidad <= 0:
            continue

        tipo_cargo = cargos_info.get(cargo_id)
        codigo_cat, _ = _categoria_para_cargo(cargo_id, tipo_cargo)
        if not codigo_cat:
            continue

        totales[codigo_cat] = totales.get(codigo_cat, 0) + cantidad
        sede_map = por_sede.setdefault(codigo_cat, {})
        sede_map[sede_id] = sede_map.get(sede_id, 0) + cantidad

    categorias: List[CategoriaPlatosResumen] = []

    definiciones = [
        ("NINOS", "Niños"),
        ("TIAS", "Tías"),
        ("ADULTOS_IMPORTANTES", "Personas Rendición"),
        ("ADULTOS_SECUNDARIOS", "Personas no Rendición"),
    ]

    for codigo, nombre in definiciones:
        sede_map = por_sede.get(codigo, {})
        categorias.append(
            CategoriaPlatosResumen(
                codigo=codigo,
                nombre=nombre,
                total=int(totales.get(codigo, 0)),
                porSede=[
                    CategoriaPlatosSede(sedeId=sid, cantidad=int(cant))
                    for sid, cant in sede_map.items()
                ],
            )
        )

    return ResumenPlatosServidosOut(desde=desde, hasta=hasta, categorias=categorias)


@app.get("/reportes/platos-por-tipo", response_model=ResumenPlatosPorTipoOut)
def resumen_platos_por_tipo(
    desde: datetime = Query(..., alias="desde"),
    hasta: datetime = Query(..., alias="hasta"),
) -> ResumenPlatosPorTipoOut:
    """Resumen de platos servidos por tipo de plato y por sede en un rango de fechas.

    - Total por tipo de plato
    - Total de cada tipo de plato por sede
    - Total general de platos
    - Total general por sede
    """

    if hasta < desde:
        raise HTTPException(status_code=400, detail="La fecha 'hasta' no puede ser menor que 'desde'")

    platos_col = get_collection("platos_historial")
    tipos_col = get_collection("tipos_platos")

    # Cargar definiciones de tipos de plato (para nombres legibles)
    tipos_docs = list(tipos_col.find({}))
    tipos_nombres: dict[str, str] = {}
    for t in tipos_docs:
        tid = t.get("_id")
        if not tid:
            continue
        tipos_nombres[str(tid)] = str(t.get("nombre", tid))

    # Acumuladores por tipo y sede
    totales_por_tipo: dict[str, int] = {}
    por_tipo_y_sede: dict[str, dict[str, int]] = {}

    total_general = 0
    total_por_sede: dict[str, int] = {}

    docs = list(
        platos_col.find({"fecha": {"$gte": desde, "$lte": hasta}})
    )

    for d in docs:
        tipo_id = str(d.get("tipoComida", ""))
        sede_id = str(d.get("sedeId", ""))
        try:
            cantidad = int(d.get("cantidadPersonas", 0))
        except (TypeError, ValueError):
            continue

        if not tipo_id or not sede_id or cantidad <= 0:
            continue

        totales_por_tipo[tipo_id] = totales_por_tipo.get(tipo_id, 0) + cantidad

        sede_map = por_tipo_y_sede.setdefault(tipo_id, {})
        sede_map[sede_id] = sede_map.get(sede_id, 0) + cantidad

        total_general += cantidad
        total_por_sede[sede_id] = total_por_sede.get(sede_id, 0) + cantidad

    tipos_resumen: List[TipoPlatoResumen] = []

    # Mantener un orden consistente por nombre de tipo de plato
    # e incluir todos los tipos definidos aunque tengan total 0.
    all_tipo_ids = set(tipos_nombres.keys()) | set(totales_por_tipo.keys())
    for tipo_id in sorted(all_tipo_ids, key=lambda k: tipos_nombres.get(k, k)):
        nombre = tipos_nombres.get(tipo_id, tipo_id)
        sede_map = por_tipo_y_sede.get(tipo_id, {})
        tipos_resumen.append(
            TipoPlatoResumen(
                codigo=tipo_id,
                nombre=nombre,
                total=int(totales_por_tipo.get(tipo_id, 0)),
                porSede=[
                    TipoPlatoSedeResumen(sedeId=sid, cantidad=int(cant))
                    for sid, cant in sede_map.items()
                ],
            )
        )

    total_por_sede_list = [
        TotalPlatosPorSede(sedeId=sid, cantidad=int(cant))
        for sid, cant in total_por_sede.items()
    ]

    return ResumenPlatosPorTipoOut(
        desde=desde,
        hasta=hasta,
        tipos=tipos_resumen,
        totalGeneral=int(total_general),
        totalPorSede=total_por_sede_list,
    )


@app.get("/reportes/platos-por-tipo-y-cargo", response_model=ResumenPlatosPorTipoYCargoOut)
def resumen_platos_por_tipo_y_cargo(
    desde: datetime = Query(..., alias="desde"),
    hasta: datetime = Query(..., alias="hasta"),
) -> ResumenPlatosPorTipoYCargoOut:
    """Resumen de platos servidos por tipo de plato, categoría de cargo y sede.

    Para cada tipo de plato (desayuno, almuerzo, etc.) se detalla cuántas
    personas comieron de cada categoría de cargo (Niños, Tías, Personas
    Rendición, Personas no Rendición) en cada sede.
    """

    if hasta < desde:
        raise HTTPException(status_code=400, detail="La fecha 'hasta' no puede ser menor que 'desde'")

    platos_col = get_collection("platos_historial")
    cargos_col = get_collection("cargos")
    tipos_col = get_collection("tipos_platos")

    # Mapa de cargos para conocer su tipo
    cargos_docs = list(cargos_col.find({}))
    cargos_info: dict[str, int] = {}
    for c in cargos_docs:
        cid = c.get("_id")
        if not cid:
            continue
        try:
            cargos_info[str(cid)] = int(c.get("tipo", 1))
        except (TypeError, ValueError):
            cargos_info[str(cid)] = 1

    # Nombres de tipos de plato
    tipos_docs = list(tipos_col.find({}))
    tipos_nombres: dict[str, str] = {}
    for t in tipos_docs:
        tid = t.get("_id")
        if not tid:
            continue
        tipos_nombres[str(tid)] = str(t.get("nombre", tid))

    # Estructura: tipo_id -> categoria_codigo -> {"nombre": str, "total": int, "porSede": {sedeId: int}}
    datos: dict[str, dict[str, dict[str, Any]]] = {}

    docs = list(
        platos_col.find({"fecha": {"$gte": desde, "$lte": hasta}})
    )

    for d in docs:
        tipo_id = str(d.get("tipoComida", ""))
        sede_id = str(d.get("sedeId", ""))
        cargo_id = str(d.get("cargoId", ""))
        try:
            cantidad = int(d.get("cantidadPersonas", 0))
        except (TypeError, ValueError):
            continue

        if not tipo_id or not sede_id or not cargo_id or cantidad <= 0:
            continue

        tipo_cargo = cargos_info.get(cargo_id)
        codigo_cat, nombre_cat = _categoria_para_cargo(cargo_id, tipo_cargo)
        if not codigo_cat or not nombre_cat:
            continue

        tipo_map = datos.setdefault(tipo_id, {})
        cat_map = tipo_map.setdefault(
            codigo_cat,
            {"nombre": nombre_cat, "total": 0, "porSede": {}},
        )

        cat_map["total"] = int(cat_map.get("total", 0)) + cantidad
        por_sede_map: dict[str, int] = cat_map.setdefault("porSede", {})  # type: ignore[assignment]
        por_sede_map[sede_id] = int(por_sede_map.get(sede_id, 0)) + cantidad

    # Construir respuesta ordenada
    tipos_resumen: List[TipoPlatoConCategoriasResumen] = []

    definiciones_categorias = [
        ("NINOS", "Niños"),
        ("TIAS", "Tías"),
        ("ADULTOS_IMPORTANTES", "Personas Rendición"),
        ("ADULTOS_SECUNDARIOS", "Personas no Rendición"),
    ]

    # Incluir todos los tipos de plato definidos aunque no tengan datos
    all_tipo_ids = set(tipos_nombres.keys()) | set(datos.keys())

    for tipo_id in sorted(all_tipo_ids, key=lambda k: tipos_nombres.get(k, k)):
        nombre_tipo = tipos_nombres.get(tipo_id, tipo_id)
        tipo_map = datos.get(tipo_id, {})

        categorias_resumen: List[TipoPlatoCategoriaResumen] = []
        for codigo_cat, nombre_cat_def in definiciones_categorias:
            cat_map = tipo_map.get(codigo_cat)
            # Si no hubo datos para esta categoría, devolver totales en 0
            if not cat_map:
                total_cat = 0
                por_sede_map: dict[str, int] = {}
            else:
                total_cat = int(cat_map.get("total", 0))
                por_sede_map = cat_map.get("porSede", {}) or {}

            categorias_resumen.append(
                TipoPlatoCategoriaResumen(
                    codigo=codigo_cat,
                    nombre=nombre_cat_def,
                    total=total_cat,
                    porSede=[
                        TipoPlatoCategoriaSedeResumen(
                            sedeId=sid,
                            cantidad=int(cant),
                        )
                        for sid, cant in por_sede_map.items()
                    ],
                )
            )

        # Siempre incluimos el tipo de plato, aunque todos los valores sean 0
        tipos_resumen.append(
            TipoPlatoConCategoriasResumen(
                codigo=tipo_id,
                nombre=nombre_tipo,
                categorias=categorias_resumen,
            )
        )

    return ResumenPlatosPorTipoYCargoOut(
        desde=desde,
        hasta=hasta,
        tipos=tipos_resumen,
    )
