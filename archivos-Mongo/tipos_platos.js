// TIPOS DE PLATOS (desayuno, merienda, almuerzo, cena)
// Ejecutar:  mongosh < 06_tipos_platos.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

// Limpiamos la colección antes de insertar

dbConn.tipos_platos.deleteMany({});

// Inserts iniciales de tipos de platos

dbConn.tipos_platos.insertMany([
  {
    _id: 'DESAYUNO',
    nombre: 'Desayuno',
    activo: 1,
  },
  {
    _id: 'MERIENDA',
    nombre: 'Merienda',
    activo: 1,
  },
  {
    _id: 'ALMUERZO',
    nombre: 'Almuerzo',
    activo: 1,
  },
  {
    _id: 'CENA',
    nombre: 'Cena',
    activo: 1,
  },
]);

print('Tipos de platos insertados en DB ' + dbName);
