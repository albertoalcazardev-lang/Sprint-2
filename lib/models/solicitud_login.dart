class SolicitudLogin {
  final String usuario;
  final String contrasena;

  const SolicitudLogin({required this.usuario, required this.contrasena});

  Map<String, dynamic> toJson() {
    return {'username': usuario, 'password': contrasena};
  }
}
