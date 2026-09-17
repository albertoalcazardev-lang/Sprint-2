import 'package:flutter/foundation.dart';

import '../core/errors/usuario_exception.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

class UsuariosViewModel extends ChangeNotifier {
  final UsuarioRepository usuarioRepository;

  UsuariosViewModel(this.usuarioRepository);

  final List<Usuario> _usuarios = [];
  bool _cargando = false;
  String? _mensajeError;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  bool get cargando => _cargando;

  String? get mensajeError => _mensajeError;

  bool get tieneUsuarios => _usuarios.isNotEmpty;

  Future<void> cargarUsuarios() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final usuariosObtenidos = await usuarioRepository.obtenerUsuarios();

      _usuarios
        ..clear()
        ..addAll(usuariosObtenidos);
    } on UsuarioException catch (error) {
      _mensajeError = error.mensaje;
    } catch (_) {
      _mensajeError = 'Ocurrió un error inesperado al cargar los usuarios.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargarUsuarios() {
    return cargarUsuarios();
  }
}