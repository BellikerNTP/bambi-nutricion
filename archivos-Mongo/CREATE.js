// Creación de colecciones ("tablas") para la app de nutrición
// Ejecutar primero:  mongosh < CREATE.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

// 1) SEDES
// ---------
// Representa cada casa / sede de Hogar Bambi

dbConn.createCollection('sedes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['_id', 'nombre', 'codigo', 'activa'],
      properties: {
        _id: { bsonType: 'string' }, // ej: CASA_PRINCIPAL
        nombre: { bsonType: 'string' },
        codigo: { bsonType: 'string' }, // ej: BE, B2, B3, etc.
        activa: { bsonType: 'int' }, // 1 = activa, 0 = inactiva
      },
    },
  },
});

dbConn.sedes.createIndex({ codigo: 1 }, { unique: true });

// 2) CARGOS
// ---------
// Grupos que reciben comida: Niños, Personal, Visitas, etc.

dbConn.createCollection('cargos', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['_id', 'nombre'],
      properties: {
        _id: { bsonType: 'string' }, // ej: NINOS
        nombre: { bsonType: 'string' },
        descripcion: { bsonType: ['string', 'null'] },
        creadoEn: { bsonType: ['date', 'null'] },
      },
    },
  },
});

dbConn.cargos.createIndex({ nombre: 1 }, { unique: true });

// 3) PRODUCTOS
// ------------
// Catálogo de productos y stocks mínimos por sede

dbConn.createCollection('productos', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: [
        '_id',
        'nombre',
        'categoria',
        'unidad',
        'stockMinBambiEnlace',
        'stockMinBambiII',
        'stockMinBambiIII',
        'stockMinBambiIV',
        'stockMinBambiV',
      ],
      properties: {
        _id: { bsonType: 'string' }, // ej: ARROZ
        nombre: { bsonType: 'string' },
        categoria: { bsonType: 'string' },
        unidad: { bsonType: 'string' }, // kg, L, etc.
        stockMinBambiEnlace: { bsonType: ['double', 'int'] },
        stockMinBambiII: { bsonType: ['double', 'int'] },
        stockMinBambiIII: { bsonType: ['double', 'int'] },
        stockMinBambiIV: { bsonType: ['double', 'int'] },
        stockMinBambiV: { bsonType: ['double', 'int'] },
      },
    },
  },
});

dbConn.productos.createIndex({ nombre: 1 }, { unique: true });

// 4) INVENTARIO POR SEDE
// -----------------------
// Estado actual del inventario por sede y producto

dbConn.createCollection('inventario_sedes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['sedeId', 'productoId', 'cantidadActual', 'estado', 'actualizadoEn'],
      properties: {
        sedeId: { bsonType: 'string' }, // referencia a sedes._id
        productoId: { bsonType: 'string' }, // referencia a productos._id
        cantidadActual: { bsonType: ['double', 'int'] },
        estado: { bsonType: 'string' }, // NORMAL, STOCK_BAJO, etc.
        actualizadoEn: { bsonType: 'date' },
      },
    },
  },
});

dbConn.inventario_sedes.createIndex({ sedeId: 1, productoId: 1 }, { unique: true });

// 5) HISTORIAL DE INVENTARIO
// ---------------------------
// Movimientos de entrada / salida / transferencia de productos

dbConn.createCollection('inventario_historial', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['fecha', 'tipo', 'productoId', 'sedeId', 'cantidad'],
      properties: {
        fecha: { bsonType: 'date' },
        tipo: { bsonType: 'string' }, // entrada, salida, transferencia
        productoId: { bsonType: 'string' }, // referencia a productos._id
        sedeId: { bsonType: 'string' }, // sede que registra el movimiento
        cantidad: { bsonType: 'double' },
        sedeOrigenId: { bsonType: ['string', 'null'] },
        sedeDestinoId: { bsonType: ['string', 'null'] },
        motivo: { bsonType: ['string', 'null'] },
        creadoEn: { bsonType: ['date', 'null'] },
      },
    },
  },
});

dbConn.inventario_historial.createIndex({ sedeId: 1, fecha: -1 });
dbConn.inventario_historial.createIndex({ productoId: 1, fecha: -1 });

// 6) HISTORIAL DE PLATOS SERVIDOS
// -------------------------------
// Registros de la sección "Platos Servidos"

dbConn.createCollection('platos_historial', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['fecha', 'sedeId', 'tipoComida', 'cargoId', 'nombrePlato', 'cantidadPersonas'],
      properties: {
        fecha: { bsonType: 'date' },
        sedeId: { bsonType: 'string' }, // referencia a sedes._id
        tipoComida: { bsonType: 'string' }, // DESAYUNO, ALMUERZO, etc.
        cargoId: { bsonType: 'string' }, // referencia a cargos._id
        nombrePlato: { bsonType: 'string' },
        ingredientes: { bsonType: ['string', 'null'] },
        cantidadPersonas: { bsonType: 'int' },
        observaciones: { bsonType: ['string', 'null'] },
        creadoEn: { bsonType: ['date', 'null'] },
      },
    },
  },
});

dbConn.platos_historial.createIndex({ sedeId: 1, fecha: -1 });
dbConn.platos_historial.createIndex({ cargoId: 1, fecha: -1 });
dbConn.platos_historial.createIndex({ tipoComida: 1, fecha: -1 });

print('Colecciones creadas y configuradas en DB ' + dbName);