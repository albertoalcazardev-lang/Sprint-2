import 'package:flutter/foundation.dart';

import '../models/sesion_usuario.dart';
import '../repositories/auth_repository.dart';

class CuentaViewModel extends ChangeNotifier {
  final AuthRepository authRepository;

  CuentaViewModel(this.authRepository);

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
    _cargando = true;
    notifyListeners();

    try {
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
