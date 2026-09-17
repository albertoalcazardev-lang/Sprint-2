import 'package:flutter/foundation.dart';

import '../models/sesion_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/carrito_repository.dart';

class CuentaViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final CarritoRepository carritoRepository;

  CuentaViewModel(this.authRepository, this.carritoRepository);

  SesionUsuario? _sesion;
  bool _cargando = false;

  SesionUsuario? get sesion => _sesion;

  bool get cargando => _cargando;

  Future<void> cargarSesion() async {
    _cargando = true;
    notifyListeners();

    try {
      _sesion = await authRepository.obtenerSesion();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> cerrarSesion() async {
    if (_cargando) {
      return false;
    }

    _cargando = true;
    notifyListeners();

    try {
      // Conservamos el ID antes de eliminar los datos de autenticación.
      final sesionActual = _sesion ?? await authRepository.obtenerSesion();

      if (sesionActual != null) {
        if (sesionActual.idUsuario <= 0) {
          return false;
        }

        // US09 — Limpiar únicamente el carrito del usuario activo.
        await carritoRepository.limpiarCarrito(sesionActual.idUsuario);
      }

      await authRepository.cerrarSesion();

      _sesion = null;

      return true;
    } catch (_) {
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
