import 'rol_usuario.dart';

class SesionUsuario {
  final String token;
  final int idUsuario;
  final RolUsuario rol;

  const SesionUsuario({
    required this.token,
    required this.idUsuario,
    required this.rol,
  });
}
