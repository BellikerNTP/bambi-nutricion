class Casa {
  Casa({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  final String id;
  final String nombre;
  final String codigo;
}

final List<Casa> casas = [
  Casa(id: '1', nombre: 'Casa Principal', codigo: 'CP'),
  Casa(id: '2', nombre: 'Casa Ángeles', codigo: 'CA'),
  Casa(id: '3', nombre: 'Casa Esperanza', codigo: 'CE'),
  Casa(id: '4', nombre: 'Casa Estrellas', codigo: 'CES'),
  Casa(id: '5', nombre: 'Casa Sueños', codigo: 'CS'),
];
