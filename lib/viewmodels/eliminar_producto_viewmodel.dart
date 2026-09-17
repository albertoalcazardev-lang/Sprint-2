import 'package:flutter/foundation.dart';

import '../core/errors/product_exception.dart';
import '../models/producto.dart';
import '../models/resultado_eliminacion_producto.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/product_repository.dart';
import 'eliminar_producto_estado.dart';

/// US08/E1-E3 — Eliminación, errores y autorización defensiva.
class EliminarProductoViewModel extends ChangeNotifier {
  final ProductRepository productRepository;
  final AuthRepository authRepository;

  EliminarProductoViewModel(this.productRepository, this.authRepository);

  EliminarProductoEstado _estado = EliminarProductoEstado.inicial;

  Producto? _productoSolicitado;
  Producto? _productoEliminado;
  ResultadoEliminacionProducto? _resultado;

  String? _mensajeError;
  bool _procesandoEliminacion = false;
  bool _disposed = false;

  EliminarProductoEstado get estado => _estado;

  Producto? get productoSolicitado => _productoSolicitado;

  Producto? get productoEliminado => _productoEliminado;

  ResultadoEliminacionProducto? get resultado => _resultado;

  String? get mensajeError => _mensajeError;

  bool get eliminando => _procesandoEliminacion;

  bool get accesoNoAutorizado =>
      _estado == EliminarProductoEstado.accesoNoAutorizado;

  bool get eliminadoCorrectamente =>
      _estado == EliminarProductoEstado.productoEliminado &&
      _productoEliminado != null &&
      _resultado != null;

  Future<bool> eliminarProducto(Producto producto) async {
    if (_procesandoEliminacion || _disposed) {
      return false;
    }

    _productoSolicitado = producto;
    _productoEliminado = null;
    _resultado = null;
    _mensajeError = null;

    if (producto.id <= 0) {
      _mensajeError = 'No se encontró el producto que intentas eliminar.';
      _estado = EliminarProductoEstado.errorRecuperable;
      _notificar();
      return false;
    }

    _procesandoEliminacion = true;
    _estado = EliminarProductoEstado.eliminando;
    _notificar();

    try {
      final esAdministrador = await _esAdministrador();

      if (_disposed) {
        return false;
      }

      if (!esAdministrador) {
        _establecerAccesoNoAutorizado(notificar: false);
        return false;
      }

      final respuesta = await productRepository.eliminarProducto(producto.id);

      if (_disposed) {
        return false;
      }

      if (respuesta.id != producto.id) {
        throw const RespuestaProductoInvalidaException(
          'La respuesta del servidor no corresponde '
          'al producto eliminado.',
        );
      }

      _productoEliminado = respuesta;
      _resultado = ResultadoEliminacionProducto(productoId: respuesta.id);
      _estado = EliminarProductoEstado.productoEliminado;

      return true;
    } on ProductoException catch (error) {
      if (_disposed) {
        return false;
      }

      _productoEliminado = null;
      _resultado = null;
      _mensajeError = error.mensaje;
      _estado = EliminarProductoEstado.errorRecuperable;

      return false;
    } catch (_) {
      if (_disposed) {
        return false;
      }

      _productoEliminado = null;
      _resultado = null;
      _mensajeError =
          'No pudimos eliminar el producto. '
          'Inténtalo nuevamente.';
      _estado = EliminarProductoEstado.errorRecuperable;

      return false;
    } finally {
      _procesandoEliminacion = false;
      _notificar();
    }
  }

  void limpiarError() {
    if (_mensajeError == null || _disposed) {
      return;
    }

    _mensajeError = null;

    if (!accesoNoAutorizado) {
      _estado = EliminarProductoEstado.inicial;
    }

    _notificar();
  }

  Future<bool> _esAdministrador() async {
    try {
      final sesion = await authRepository.obtenerSesion();

      return sesion?.rol == RolUsuario.administrador;
    } catch (_) {
      return false;
    }
  }

  void _establecerAccesoNoAutorizado({bool notificar = true}) {
    _productoEliminado = null;
    _resultado = null;
    _mensajeError = 'No tienes acceso a esta sección.';
    _estado = EliminarProductoEstado.accesoNoAutorizado;

    if (notificar) {
      _notificar();
    }
  }

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
