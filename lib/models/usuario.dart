class Usuario {
  final int id;
  final String usuario;
  final String correo;
  final String nombre;
  final String apellido;
  final String telefono;

  const Usuario({
    required this.id,
    required this.usuario,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.telefono,
  });

  String get nombreCompleto {
    final nombreCompleto = '$nombre $apellido'.trim();

    if (nombreCompleto.isEmpty) {
      return usuario;
    }

    return nombreCompleto;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final nombreJson = json['name'] is Map
        ? Map<String, dynamic>.from(json['name'])
        : <String, dynamic>{};

    return Usuario(
      id: (json['id'] as num).toInt(),
      usuario: json['username']?.toString() ?? '',
      correo: json['email']?.toString() ?? '',
      nombre: nombreJson['firstname']?.toString() ?? '',
      apellido: nombreJson['lastname']?.toString() ?? '',
      telefono: json['phone']?.toString() ?? '',
    );
  }
}