// Base de datos para la app de nutrición
// Ejecutar en el shell de MongoDB con:  mongosh < 01_sedes.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

// SEDES (casas)
dbConn.sedes.deleteMany({});

dbConn.sedes.insertMany([
  {
    _id: 'CASA_PRINCIPAL',
    nombre: 'Casa Principal',
    codigo: 'CP',
    direccion: 'Caracas, Venezuela',
    telefono: '+58 000-0000000',
    activa: true,
    creadoEn: new Date(),
  },
  {
    _id: 'CASA_ANGELES',
    nombre: 'Casa Ángeles',
    codigo: 'CA',
    direccion: 'Caracas, Venezuela',
    telefono: '+58 000-0000001',
    activa: true,
    creadoEn: new Date(),
  },
  {
    _id: 'CASA_ESPERANZA',
    nombre: 'Casa Esperanza',
    codigo: 'CE',
    direccion: 'Caracas, Venezuela',
    telefono: '+58 000-0000002',
    activa: true,
    creadoEn: new Date(),
  },
]);

print('Sedes insertadas en DB ' + dbName);