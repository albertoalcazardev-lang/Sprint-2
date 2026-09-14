import '../core/storage/secure_storage.dart';
import '../core/utils/mapeador_rol.dart';
import '../models/rol_usuario.dart';
import '../models/sesion_usuario.dart';
import '../models/solicitud_login.dart';
import '../models/usuario_autenticacion.dart';
import '../services/auth_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService authService;
  final SecureStorage secureStorage;
  final MapeadorRol mapeadorRol;

  static const String _claveToken = 'token';
  static const String _claveIdUsuario = 'idUsuario';
  static const String _claveRol = 'rol';

  AuthRepositoryImpl(this.authService, this.secureStorage, this.mapeadorRol);

  @override
  Future<SesionUsuario> iniciarSesion(SolicitudLogin solicitud) async {
    final respuesta = await authService.iniciarSesion(solicitud);

    final usuarios = await authService.obtenerUsuarios();

    UsuarioAutenticacion? usuarioEncontrado;

    for (final usuario in usuarios) {
      if (usuario.usuario == solicitud.usuario) {
        usuarioEncontrado = usuario;
        break;
      }
    }

    if (usuarioEncontrado == null) {
      throw StateError('No se pudo identificar al usuario autenticado.');
    }

    final rol = mapeadorRol.obtenerRolPorId(usuarioEncontrado.id);

    await secureStorage.guardar(_claveToken, respuesta.token);

    await secureStorage.guardar(
      _claveIdUsuario,
      usuarioEncontrado.id.toString(),
    );

    await secureStorage.guardar(_claveRol, rol.name);

    return SesionUsuario(
      token: respuesta.token,
      idUsuario: usuarioEncontrado.id,
      rol: rol,
    );
  }

  @override
  Future<SesionUsuario?> obtenerSesion() async {
    final token = await secureStorage.obtener(_claveToken);
    final idGuardado = await secureStorage.obtener(_claveIdUsuario);
    final rolGuardado = await secureStorage.obtener(_claveRol);

    if (token == null || idGuardado == null || rolGuardado == null) {
      return null;
    }

    final idUsuario = int.tryParse(idGuardado);

    RolUsuario? rol;

    for (final valor in RolUsuario.values) {
      if (valor.name == rolGuardado) {
        rol = valor;
        break;
      }
    }

    if (idUsuario == null || rol == null) {
      return null;
    }

    return SesionUsuario(token: token, idUsuario: idUsuario, rol: rol);
  }

  @override
  Future<void> cerrarSesion() async {
    await secureStorage.eliminar(_claveToken);
    await secureStorage.eliminar(_claveIdUsuario);
    await secureStorage.eliminar(_claveRol);
  }
}
