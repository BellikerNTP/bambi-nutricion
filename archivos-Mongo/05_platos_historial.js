// HISTORIAL de platos servidos (registros de la sección Platos Servidos)
// Ejecutar:  mongosh < 05_platos_historial.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.platos_historial.deleteMany({});

// tipoComida: 'DESAYUNO', 'MERIENDA_MATUTINA', 'ALMUERZO', 'MERIENDA_VESPERTINA', 'CENA'

dbConn.platos_historial.insertMany([
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-28T07:30:00Z'),
    sedeId: 'CASA_PRINCIPAL',
    tipoComida: 'DESAYUNO',
    cargoId: 'NINOS',
    nombrePlato: 'Panqueques',
    ingredientes: 'Harina, huevos, leche, azúcar',
    cantidadPersonas: 25,
    observaciones: 'Buena aceptación general',
    creadoEn: new Date(),
  },
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-28T12:30:00Z'),
    sedeId: 'CASA_PRINCIPAL',
    tipoComida: 'ALMUERZO',
    cargoId: 'PERSONAL',
    nombrePlato: 'Arroz con pollo',
    ingredientes: 'Arroz, pollo, vegetales',
    cantidadPersonas: 15,
    observaciones: '',
    creadoEn: new Date(),
  },
  {
    _id: ObjectId(),
    fecha: ISODate('2025-01-28T15:30:00Z'),
    sedeId: 'CASA_PRINCIPAL',
    tipoComida: 'MERIENDA_MATUTINA',
    cargoId: 'NINOS',
    nombrePlato: 'Frutas variadas',
    ingredientes: 'Manzana, banana, papaya',
    cantidadPersonas: 25,
    observaciones: 'Porciones suficientes',
    creadoEn: new Date(),
  },
]);

// Índices para reportes por sede, fecha, cargo y tipo de comida

dbConn.platos_historial.createIndex({ sedeId: 1, fecha: -1 });
dbConn.platos_historial.createIndex({ cargoId: 1, fecha: -1 });
dbConn.platos_historial.createIndex({ tipoComida: 1, fecha: -1 });

print('Historial de platos servidos insertado en DB ' + dbName);