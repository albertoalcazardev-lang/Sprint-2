import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/carrito_exception.dart';
import '../models/carrito_snapshot.dart';
import '../models/item_carrito.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/carrito_repository.dart';
import '../repositories/gestion_carrito_repository.dart';
import 'carrito_estado.dart';

/// US10/E1-E4 — Presentación, autorización y operaciones del carrito personal.
class CarritoViewModel extends ChangeNotifier {
  final CarritoRepository carritoRepository;
  final GestionCarritoRepository gestionCarritoRepository;
  final AuthRepository authRepository;
  final DateTime Function() obtenerFechaActual;

  CarritoViewModel(
    this.carritoRepository,
    this.gestionCarritoRepository,
    this.authRepository, {
    DateTime Function()? obtenerFechaActual,
  }) : obtenerFechaActual = obtenerFechaActual ?? DateTime.now;

  CarritoEstado _estado = CarritoEstado.inicial;
  CarritoSnapshot? _carrito;
  int? _idUsuario;
  String? _mensajeError;
  String? _mensajeInformativo;
  bool _disposed = false;

  final Set<int> _productosProcesando = <int>{};
  StreamSubscription<CarritoSnapshot>? _suscripcion;

  CarritoEstado get estado => _estado;
  CarritoSnapshot? get carrito => _carrito;
  List<ItemCarrito> get items => _carrito?.items ?? const [];
  double get total => _carrito?.total ?? 0;
  int get totalUnidades => _carrito?.totalUnidades ?? 0;
  String? get mensajeError => _mensajeError;
  String? get mensajeInformativo => _mensajeInformativo;
  bool get accesoNoAutorizado => _estado == CarritoEstado.accesoNoAutorizado;
  bool get estaCargando => _estado == CarritoEstado.cargando;
  bool get estaVacio => _carrito?.estaVacio ?? false;
  bool get puedeProcederAlPago => !estaCargando && items.isNotEmpty;

  bool estaProcesando(int productoId) {
    return _productosProcesando.contains(productoId);
  }

  Future<void> inicializar() async {
    if (_disposed || _estado == CarritoEstado.cargando) {
      return;
    }

    _estado = CarritoEstado.cargando;
    _mensajeError = null;
    _mensajeInformativo = null;
    _notificar();

    try {
      final sesion = await authRepository.obtenerSesion();

      if (_disposed) {
        return;
      }

      if (sesion == null || sesion.rol != RolUsuario.cliente) {
        _estado = CarritoEstado.accesoNoAutorizado;
        _mensajeError = 'No tienes acceso a esta sección.';
        _notificar();
        return;
      }

      if (sesion.idUsuario <= 0) {
        throw const DatosCarritoInvalidosException(
          'No se pudo identificar al usuario del carrito.',
        );
      }

      _idUsuario = sesion.idUsuario;
      await _suscripcion?.cancel();
      _suscripcion = carritoRepository
          .observarCarrito(sesion.idUsuario)
          .listen(_procesarCambioLocal);

      _carrito = await carritoRepository.obtenerCarritoActual(sesion.idUsuario);

      if (_disposed) {
        return;
      }

      _actualizarEstadoPorContenido();
      _notificar();
    } on CarritoException catch (error) {
      _mostrarError(error.mensaje);
    } catch (_) {
      _mostrarError('No pudimos cargar tu carrito. Inténtalo nuevamente.');
    }
  }

  Future<bool> incrementar(int productoId) async {
    final item = _carrito?.buscarProducto(productoId);

    if (item == null) {
      _mostrarError('El producto ya no está en el carrito.');
      return false;
    }

    return _actualizarCantidad(item, item.cantidad + 1);
  }

  Future<bool> disminuir(int productoId) async {
    final item = _carrito?.buscarProducto(productoId);

    if (item == null) {
      _mostrarError('El producto ya no está en el carrito.');
      return false;
    }

    if (item.cantidad == 1) {
      return eliminar(productoId);
    }

    return _actualizarCantidad(item, item.cantidad - 1);
  }

  Future<bool> eliminar(int productoId) async {
    if (!_puedeIniciarOperacion(productoId)) {
      return false;
    }

    final idUsuario = await _validarSesionAntesDeOperar(productoId);

    if (idUsuario == null || _disposed) {
      return false;
    }

    _productosProcesando.add(productoId);
    _estado = CarritoEstado.eliminando;
    _limpiarAvisosInterno();
    _notificar();

    try {
      _carrito = await gestionCarritoRepository.eliminarProducto(
        idUsuario: idUsuario,
        productoId: productoId,
      );

      if (_disposed) {
        return false;
      }

      _mensajeInformativo = 'Producto eliminado del carrito (Simulación).';
      return true;
    } on CarritoException catch (error) {
      if (!_disposed) {
        _mensajeError = error.mensaje;
      }
      return false;
    } catch (_) {
      if (!_disposed) {
        _mensajeError =
            'No pudimos eliminar el producto. Inténtalo nuevamente.';
      }
      return false;
    } finally {
      _productosProcesando.remove(productoId);
      _actualizarEstadoPorContenido();
      _notificar();
    }
  }

  void mostrarAvisoPago() {
    if (!puedeProcederAlPago || _disposed) {
      return;
    }

    _mensajeError = null;
    _mensajeInformativo = 'El proceso de pago aún no está definido.';
    _notificar();
  }

  void limpiarAvisos() {
    if (_disposed) {
      return;
    }

    _limpiarAvisosInterno();
    _notificar();
  }

  Future<bool> _actualizarCantidad(ItemCarrito item, int nuevaCantidad) async {
    final productoId = item.producto.id;

    if (!_puedeIniciarOperacion(productoId)) {
      return false;
    }

    final idUsuario = await _validarSesionAntesDeOperar(productoId);

    if (idUsuario == null || _disposed) {
      return false;
    }

    _productosProcesando.add(productoId);
    _estado = CarritoEstado.actualizando;
    _limpiarAvisosInterno();
    _notificar();

    try {
      _carrito = await gestionCarritoRepository.actualizarCantidad(
        idUsuario: idUsuario,
        productoId: productoId,
        nuevaCantidad: nuevaCantidad,
        fecha: obtenerFechaActual(),
      );

      if (_disposed) {
        return false;
      }

      return true;
    } on CarritoException catch (error) {
      if (!_disposed) {
        _mensajeError = error.mensaje;
      }
      return false;
    } catch (_) {
      if (!_disposed) {
        _mensajeError =
            'No pudimos actualizar la cantidad. Inténtalo nuevamente.';
      }
      return false;
    } finally {
      _productosProcesando.remove(productoId);
      _actualizarEstadoPorContenido();
      _notificar();
    }
  }

  bool _puedeIniciarOperacion(int productoId) {
    if (_disposed || _productosProcesando.contains(productoId)) {
      return false;
    }

    if (_carrito?.buscarProducto(productoId) == null) {
      _mostrarError('El producto ya no está en el carrito.');
      return false;
    }

    return true;
  }

  Future<int?> _validarSesionAntesDeOperar(int productoId) async {
    final sesion = await authRepository.obtenerSesion();

    if (_disposed) {
      return null;
    }

    if (sesion == null ||
        sesion.rol != RolUsuario.cliente ||
        sesion.idUsuario != _idUsuario) {
      _productosProcesando.remove(productoId);
      _estado = CarritoEstado.accesoNoAutorizado;
      _mensajeError = 'No tienes acceso a esta sección.';
      _notificar();
      return null;
    }

    return sesion.idUsuario;
  }

  void _procesarCambioLocal(CarritoSnapshot carritoActualizado) {
    if (_disposed || carritoActualizado.idUsuario != _idUsuario) {
      return;
    }

    _carrito = carritoActualizado;
    _notificar();
  }

  void _actualizarEstadoPorContenido() {
    if (_disposed || accesoNoAutorizado) {
      return;
    }

    if (_productosProcesando.isNotEmpty) {
      return;
    }

    _estado = (_carrito?.items.isEmpty ?? true)
        ? CarritoEstado.vacio
        : CarritoEstado.listo;
  }

  void _mostrarError(String mensaje) {
    if (_disposed) {
      return;
    }

    _mensajeError = mensaje;
    _mensajeInformativo = null;
    _estado = CarritoEstado.errorRecuperable;
    _notificar();
  }

  void _limpiarAvisosInterno() {
    _mensajeError = null;
    _mensajeInformativo = null;
  }

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _suscripcion?.cancel();
    super.dispose();
  }
}
