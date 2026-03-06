// PRODUCTOS de inventario
// Ejecutar:  mongosh < 03_productos.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.productos.deleteMany({});

dbConn.productos.insertMany([
  {
    _id: 'BISTEC',
    nombre: 'Bistec',
    categoria: 'Carnes',
    unidad: 'kg',
    stockMinBambiEnlace: 32,
    stockMinBambiII: 7,
    stockMinBambiIII: 18,
    stockMinBambiIV: 7,
    stockMinBambiV: 8,
    cantidadActual: 72,
    estado: 'NORMAL', // Estado posible: 'NORMAL', 'STOCK_BAJO'
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  
]);

// Índices útiles para búsquedas por nombre

dbConn.productos.createIndex({ nombre: 1 }, { unique: true });

print('Productos insertados en DB ' + dbName);