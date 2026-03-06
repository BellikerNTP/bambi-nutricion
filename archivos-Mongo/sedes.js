// Base de datos para la app de nutrición
// Ejecutar en el shell de MongoDB con:  mongosh < 01_sedes.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

// SEDES (casas)
dbConn.sedes.deleteMany({});

dbConn.sedes.insertMany([
  {
    _id: 'BAMBI_ENLACE',
    nombre: 'Bambi Enlace',
    codigo: 'BE',
    activa: 1,
  },
  {
    _id: 'BAMBI_II',
    nombre: 'Bambi II',
    codigo: 'B2',
    activa: 1,
  },
  {
    _id: 'BAMBI_III',
    nombre: 'Bambi III',
    codigo: 'B3',
    activa: 1,
  },
  {
    _id: 'BAMBI_IV',
    nombre: 'Bambi IV',
    codigo: 'B4',
    activa: 1,
  },
  {
    _id: 'BAMBI_V',
    nombre: 'Bambi V',
    codigo: 'B5',
    activa: 1,
  },
]);

print('Sedes insertadas en DB ' + dbName);