// HISTORIAL de movimientos de inventario
// Ejecutar:  mongosh < 04_inventario_historial.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.inventario_historial.deleteMany({});

// tipo: 'entrada', 'salida', 'transferencia'
// Cada documento representa una transacción de inventario

dbConn.inventario_historial.insertMany([
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-28T10:00:00Z'),
    tipo: 'entrada',
    productoId: 'ARROZ',
    sedeId: 'CASA_PRINCIPAL',
    cantidad: 20,
    motivo: 'Compra mensual',
    creadoEn: new Date(),
  },
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-28T11:00:00Z'),
    tipo: 'salida',
    productoId: 'FRIJOLES',
    sedeId: 'CASA_PRINCIPAL',
    cantidad: 5,
    motivo: 'Preparación almuerzo',
    creadoEn: new Date(),
  },
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-27T09:30:00Z'),
    tipo: 'transferencia',
    productoId: 'ACEITE',
    sedeId: 'CASA_PRINCIPAL', // sede que registra el movimiento
    cantidad: 3,
    sedeOrigenId: 'CASA_PRINCIPAL',
    sedeDestinoId: 'CASA_ANGELES',
    motivo: 'Préstamo a Casa Ángeles',
    creadoEn: new Date(),
  },
]);

// Índices para consultas rápidas por sede / fecha / producto

dbConn.inventario_historial.createIndex({ sedeId: 1, fecha: -1 });
dbConn.inventario_historial.createIndex({ productoId: 1, fecha: -1 });

print('Historial de inventario insertado en DB ' + dbName);