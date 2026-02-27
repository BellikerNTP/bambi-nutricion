// PRODUCTOS de inventario
// Ejecutar:  mongosh < 03_productos.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.productos.deleteMany({});

// Estado posible: 'NORMAL', 'STOCK_BAJO'
dbConn.productos.insertMany([
  {
    _id: 'ARROZ',
    nombre: 'Arroz',
    categoria: 'Granos',
    unidad: 'kg',
    stockMinimo: 30,
    cantidadActual: 45,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'NORMAL',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  {
    _id: 'FRIJOLES',
    nombre: 'Frijoles',
    categoria: 'Granos',
    unidad: 'kg',
    stockMinimo: 20,
    cantidadActual: 22,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'NORMAL',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  {
    _id: 'ACEITE',
    nombre: 'Aceite',
    categoria: 'Condimentos',
    unidad: 'L',
    stockMinimo: 10,
    cantidadActual: 15,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'NORMAL',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  {
    _id: 'AZUCAR',
    nombre: 'Azúcar',
    categoria: 'Endulzantes',
    unidad: 'kg',
    stockMinimo: 15,
    cantidadActual: 18,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'NORMAL',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  {
    _id: 'PASTA',
    nombre: 'Pasta',
    categoria: 'Granos',
    unidad: 'kg',
    stockMinimo: 20,
    cantidadActual: 12,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'STOCK_BAJO',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
  {
    _id: 'LECHE_POLVO',
    nombre: 'Leche en Polvo',
    categoria: 'Lácteos',
    unidad: 'kg',
    stockMinimo: 12,
    cantidadActual: 8,
    sedeId: 'CASA_PRINCIPAL',
    estado: 'STOCK_BAJO',
    creadoEn: new Date(),
    actualizadoEn: new Date(),
  },
]);

// Índices útiles para búsquedas por sede y nombre

dbConn.productos.createIndex({ sedeId: 1, nombre: 1 }, { unique: true });

print('Productos insertados en DB ' + dbName);