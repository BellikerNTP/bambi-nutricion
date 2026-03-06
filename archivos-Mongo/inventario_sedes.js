// INVENTARIO actual por sede y producto
// Ejecutar:  mongosh < inventario_sedes.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

// Limpiar inventario actual
dbConn.inventario_sedes.deleteMany({});

// Cargar sedes y productos existentes
const sedes = dbConn.sedes.find({}).toArray();
const productos = dbConn.productos.find({}).toArray();

const ahora = new Date();
const inventarioDocs = [];

sedes.forEach((sede) => {
  productos.forEach((producto) => {
    inventarioDocs.push({
      sedeId: sede._id,
      productoId: producto._id,
      cantidadActual: 0,
      estado: 'NORMAL',
      actualizadoEn: ahora,
    });
  });
});

if (inventarioDocs.length > 0) {
  dbConn.inventario_sedes.insertMany(inventarioDocs);
}

// Índice para consultas por sede y producto
dbConn.inventario_sedes.createIndex({ sedeId: 1, productoId: 1 }, { unique: true });

print('Inventario por sede inicializado en DB ' + dbName);
