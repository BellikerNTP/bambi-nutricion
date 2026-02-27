// CARGOS (quién recibe la comida)
// Ejecutar:  mongosh < 02_cargos.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.cargos.deleteMany({});

dbConn.cargos.insertMany([
  {
    _id: 'NINOS',
    nombre: 'Niños',
    descripcion: 'Niños y niñas atendidos en la sede',
    creadoEn: new Date(),
  },
  {
    _id: 'PERSONAL',
    nombre: 'Personal',
    descripcion: 'Personal que trabaja en la sede',
    creadoEn: new Date(),
  },
  {
    _id: 'VISITAS',
    nombre: 'Visitas',
    descripcion: 'Visitantes puntuales',
    creadoEn: new Date(),
  },
  {
    _id: 'VOLUNTARIOS',
    nombre: 'Voluntarios',
    descripcion: 'Voluntarios que apoyan en la sede',
    creadoEn: new Date(),
  },
  {
    _id: 'TODOS',
    nombre: 'Todos',
    descripcion: 'Cuando aplica a todos los grupos',
    creadoEn: new Date(),
  },
]);

print('Cargos insertados en DB ' + dbName);