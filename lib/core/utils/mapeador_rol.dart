import '../../models/rol_usuario.dart';

class MapeadorRol {
  RolUsuario obtenerRolPorId(int idUsuario) {
    if (idUsuario == 1 || idUsuario == 2) {
      return RolUsuario.administrador;
    }

    if (idUsuario == 3) {
      return RolUsuario.auditor;
    }

    return RolUsuario.cliente;
  }
}
