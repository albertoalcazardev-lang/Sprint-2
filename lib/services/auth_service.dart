import '../models/respuesta_login.dart';
import '../models/solicitud_login.dart';
import '../models/usuario_autenticacion.dart';

abstract class AuthService {
  Future<RespuestaLogin> iniciarSesion(SolicitudLogin solicitud);

  Future<List<UsuarioAutenticacion>> obtenerUsuarios();
}
