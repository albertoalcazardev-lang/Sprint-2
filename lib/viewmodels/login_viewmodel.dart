import 'package:flutter/foundation.dart';

import '../core/errors/auth_exception.dart';
import '../core/network/conectividad_service.dart';
import '../models/sesion_usuario.dart';
import '../models/solicitud_login.dart';
import '../repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final ConectividadService conectividadService;

  LoginViewModel(this.authRepository, this.conectividadService);

  bool _cargando = false;
  String? _mensajeError;
  SesionUsuario? _sesion;

  bool get cargando => _cargando;

  String? get mensajeError => _mensajeError;

  SesionUsuario? get sesion => _sesion;

  Future<bool> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    if (usuario.trim().isEmpty || contrasena.isEmpty) {
      _mensajeError = 'Ingresa tu usuario y contraseña.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _mensajeError = null;
    _sesion = null;
    notifyListeners();

    try {
      final hayConexion = await conectividadService.hayConexion();

      if (!hayConexion) {
        _mensajeError = 'Sin conexión. Revisa tu acceso a internet.';
        return false;
      }

      _sesion = await authRepository.iniciarSesion(
        SolicitudLogin(usuario: usuario.trim(), contrasena: contrasena),
      );

      return true;
    } on CredencialesInvalidasException {
      _mensajeError = 'Usuario o contraseña inválidos';
      return false;
    } on SinConexionException {
      _mensajeError = 'Sin conexión. Revisa tu acceso a internet.';
      return false;
    } on AutenticacionException catch (error) {
      _mensajeError = error.mensaje;
      return false;
    } catch (_) {
      _mensajeError = 'Ocurrió un error inesperado.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _mensajeError = null;
    notifyListeners();
  }
}
