// CARGOS (quién recibe la comida)
// Ejecutar:  mongosh < 02_cargos.js

const dbName = 'nutricion_hogar_bambi';
const dbConn = db.getSiblingDB(dbName);

dbConn.cargos.deleteMany({});

dbConn.cargos.insertMany([
  {
    _id: "NNA",
    nombre: "Niños",
    tipo: 2,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },

  // Tias cuidadoras

  {
    _id: "TIAS",
    nombre: "Tias cuidadoras",
    tipo: 2,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "TIAS_MATUTINAS",
    nombre: "Tias cuidadoras matutinas G1",
    tipo: 2,
    sedes: ["BAMBI_ENLACE"]
  },
  {
    _id: "TIAS_VESPERTINAS",
    nombre: "Tias cuidadoras vespertinas G2",
    tipo: 2,
    sedes: ["BAMBI_ENLACE"]
  },
  {
    _id: "TIAS_NOCTURNAS3",
    nombre: "Tias cuidadoras nocturnas G3",
    tipo: 2,
    sedes: ["BAMBI_ENLACE"]
  },
  {
    _id: "TIAS_NOCTURNAS4",
    nombre: "Tias cuidadoras nocturnas G4",
    tipo: 2,
    sedes: ["BAMBI_ENLACE"]
  },
  {
    _id: "TIAS_PREVENTIVO",
    nombre: "Tias aislamiento preventivo",
    tipo: 2,
    sedes: ["BAMBI_ENLACE"]
  },

  // PERSONAL

  {
    _id: "COCINA",
    nombre: "Cocina",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_V"]
  },
  {
    _id: "AUX_COCINA",
    nombre: "Auxiliar de cocina",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_ENLACE"]
  },
  {
    _id: "ENFERMERIA",
    nombre: "Enfermeria",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "LAVANDERIA",
    nombre: "Lavanderia",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "CONDUCTOR",
    nombre: "Conductor",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_ENLACE"]
  },
  {
    _id: "DIRECTOR_OPERATIVO",
    nombre: "Director Operativo",
    tipo: 1,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "COORDINADOR_OPERATIVO",
    nombre: "Coordinador operativo",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "MANTENIMIENTO",
    nombre: "Mantenimiento",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "SERVICIOS_GENERALES",
    nombre: "Servicios generales",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "DOCENTES",
    nombre: "Docentes",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "PSICOPEDAGOGAS",
    nombre: "Psicopedagogas",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "PSICOLOGIA",
    nombre: "Psicologia",
    tipo: 1,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "COORDINADORA_SALUD",
    nombre: "Coordinadora area de salud",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "MEDICOS",
    nombre: "Medicos",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "COORDINADOR_PEDIATRIA",
    nombre: "Coordinador pediatria",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "ASISTENTE_PEDIATRIA",
    nombre: "Asistente pediatria",
    tipo: 2,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "TRABAJO_SOCIAL",
    nombre: "Trabajo social",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "TERAPISTA_LENGUAJE",
    nombre: "Terapista de lenguaje",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "TERAPISTA_OCUPACIONAL",
    nombre: "Terapista ocupacional",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "FISIOTERAPEUTA",
    nombre: "Fisioterapeuta",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "NUTRICIONISTA",
    nombre: "Nutricionista",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "ADMINISTRATIVO",
    nombre: "Administrativo",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "ASISTENTE_ADMINISTRATIVO",
    nombre: "Asistente administrativo",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "DIRECCION_EJECUTIVA",
    nombre: "Direccion ejecutiva",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "ASISTENTE_DIRECCION_EJECUTIVA",
    nombre: "Asistente direccion ejecutiva",
    tipo: 1,
    sedes: ["BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "COORDINADORA_RRHH",
    nombre: "Coordinadora RRHH",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "DIREC_RELAC_INSTITUCIONALES_Y_RECAUDACION",
    nombre: "Directora Relacion Institucional y recaudación",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_DONACIONES_EVENTOS",
    nombre: "Coordinador de donaciones y eventos",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_VOLUNTARIADO",
    nombre: "Coordinador de voluntariado",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_ESTUDIANTES",
    nombre: "Coordinador de estudiantes",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_PROYECTOS",
    nombre: "Coordinador de proyectos",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_PADRINO",
    nombre: "Coordinador de padrino",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_SERVICIOS_GENERALES",
    nombre: "Coordinador de servicios generales",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "ASISTENTE_PROYECTO",
    nombre: "Asistente de proyecto",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_NUTRICION",
    nombre: "Coordinador nutricion",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "ASISTENTE_COCINA",
    nombre: "Asistente de cocina",
    tipo: 2,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "COORDINADOR_EDUCATIVO",
    nombre: "Coordinador educativo",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "VOLUNTARIADO",
    nombre: "Voluntariado",
    tipo: 1,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },
  {
    _id: "AUDITORIA_INTERNA",
    nombre: "Auditoria interna",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "ASISTENTE_ADMINISTRATIVO_JUNTA",
    nombre: "Asistente administrativo de la Junta",
    tipo: 1,
    sedes: ["BAMBI_III"]
  },
  {
    _id: "TUTOR_ACADEMICO",
    nombre: "Tutor academico",
    tipo: 2,
    sedes: ["BAMBI_II", "BAMBI_IV"]
  },
  {
    _id: "PROYECTO_EDUCATIVO",
    nombre: "Proyecto educativo",
    tipo: 1,
    sedes: ["BAMBI_II"]
  },

  //Extra

  {
    _id: "EXTRA",
    nombre: "Extra",
    tipo: 1,
    sedes: ["BAMBI_II", "BAMBI_III", "BAMBI_IV", "BAMBI_V", "BAMBI_ENLACE"]
  },

]);

print('Cargos insertados en DB ' + dbName);