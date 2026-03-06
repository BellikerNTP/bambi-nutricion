class Sede {
  Sede({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  final String id;
  final String nombre;
  final String codigo;

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String? ?? '',
    );
  }
}
