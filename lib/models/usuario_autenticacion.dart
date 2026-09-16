class UsuarioAutenticacion {
  final int id;
  final String usuario;

  const UsuarioAutenticacion({required this.id, required this.usuario});

  factory UsuarioAutenticacion.fromJson(Map<String, dynamic> json) {
    return UsuarioAutenticacion(
      id: json['id'] as int,
      usuario: json['username'] as String,
    );
  }
}
