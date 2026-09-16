import '../../models/rol_usuario.dart';

class RutaPorRol {
  RutaPorRol._();

  static String obtener(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return '/administrador';
      case RolUsuario.auditor:
        return '/auditor';
      case RolUsuario.cliente:
        return '/cliente';
    }
  }
}
