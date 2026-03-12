"""API de FastAPI para la app de Nutrición Hogar Bambi.

Por ahora se enfoca en:
- Inventario (productos + historial de movimientos)
- Platos servidos (historial y registro de nuevos platos)
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

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


# ---------
# ENDPOINTS
# ---------


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


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

        # Stock mínimo requerido en la sede destino
        stock_min_destino = _stock_min_for_sede(prod, sede_destino)
        if stock_min_destino <= 0:
            raise HTTPException(
                status_code=400,
                detail="No hay stock mínimo configurado para la sede destino",
            )

        inv_destino = inventario_col.find_one({
            "sedeId": sede_destino,
            "productoId": payload.productoId,
        }) or {}
        cantidad_destino = float(inv_destino.get("cantidadActual", 0))

        faltante = stock_min_destino - cantidad_destino
        if faltante <= 0:
            raise HTTPException(
                status_code=400,
                detail="La sede destino ya cumple o supera el stock mínimo para este producto",
            )

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
