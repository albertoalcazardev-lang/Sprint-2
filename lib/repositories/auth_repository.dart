import '../models/sesion_usuario.dart';
import '../models/solicitud_login.dart';

abstract class AuthRepository {
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud);

  Future<SesionUsuario?> obtenerSesion();

  Future<void> cerrarSesion();
}
