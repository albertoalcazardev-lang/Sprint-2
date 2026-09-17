import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/carrito_exception.dart';
import '../models/agregar_carrito_input.dart';
import '../models/carrito_snapshot.dart';
import '../models/producto.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/carrito_repository.dart';
import 'agregar_carrito_estado.dart';

/// US09/E1-E3 — Agregado, cantidades y autorización defensiva.
class AgregarCarritoViewModel extends ChangeNotifier {
  final CarritoRepository carritoRepository;
  final AuthRepository authRepository;
  final DateTime Function() obtenerFechaActual;

  AgregarCarritoViewModel(
    this.carritoRepository,
    this.authRepository, {
    DateTime Function()? obtenerFechaActual,
  }) : obtenerFechaActual = obtenerFechaActual ?? DateTime.now;

  AgregarCarritoEstado _estado = AgregarCarritoEstado.inicial;

  Producto? _producto;
  CarritoSnapshot? _carrito;
  RolUsuario? _rolActual;
  int? _idUsuario;

  int _cantidad = 1;
  bool _procesando = false;
  bool _disposed = false;

  String? _mensajeError;
  String? _mensajeExito;

  StreamSubscription<CarritoSnapshot>? _suscripcionCarrito;

  AgregarCarritoEstado get estado => _estado;

  Producto? get producto => _producto;

  CarritoSnapshot? get carrito => _carrito;

  RolUsuario? get rolActual => _rolActual;

  int get cantidad => _cantidad;

  int get totalUnidades => _carrito?.totalUnidades ?? 0;

  String? get mensajeError => _mensajeError;

  String? get mensajeExito => _mensajeExito;

  bool get agregando =>
      _procesando && _estado == AgregarCarritoEstado.agregando;

  bool get puedeMostrarControles =>
      _rolActual == RolUsuario.cliente &&
      _producto != null &&
      _producto!.id > 0;

  bool get puedeDisminuir {
    return puedeMostrarControles && !agregando && _cantidad > 1;
  }

  bool get puedeAgregar {
    return puedeMostrarControles && !agregando;
  }

  bool get accesoNoAutorizado =>
      _estado == AgregarCarritoEstado.accesoNoAutorizado;

  String? get mensajeSoloLectura {
    if (_rolActual == RolUsuario.auditor) {
      return 'Solo lectura · Perfil Auditor';
    }

    return null;
  }

  Future<void> inicializar(Producto producto) async {
    if (_disposed) {
      return;
    }

    _producto = producto;
    _cantidad = 1;
    _carrito = null;
    _rolActual = null;
    _idUsuario = null;
    _mensajeError = null;
    _mensajeExito = null;
    _estado = AgregarCarritoEstado.inicial;

    if (producto.id <= 0) {
      _establecerError('No se encontró el producto.');
      _notificar();
      return;
    }

    try {
      final sesion = await authRepository.obtenerSesion();

      if (_disposed) {
        return;
      }

      _rolActual = sesion?.rol;
      _idUsuario = sesion?.idUsuario;

      if (sesion == null) {
        _estado = AgregarCarritoEstado.accesoNoAutorizado;
        _mensajeError = 'Tu sesión ya no permite realizar esta operación.';
        _notificar();
        return;
      }

      if (sesion.rol != RolUsuario.cliente) {
        _estado = AgregarCarritoEstado.accesoNoAutorizado;
        _mensajeError = null;
        _notificar();
        return;
      }

      if (sesion.idUsuario <= 0) {
        _establecerError('No se pudo identificar al usuario del carrito.');
        _notificar();
        return;
      }

      await _suscripcionCarrito?.cancel();

      _suscripcionCarrito = carritoRepository
          .observarCarrito(sesion.idUsuario)
          .listen(_procesarCambioCarrito);

      _carrito = await carritoRepository.obtenerCarritoActual(sesion.idUsuario);

      if (_disposed) {
        return;
      }

      _estado = AgregarCarritoEstado.listo;
      _notificar();
    } on CarritoException catch (error) {
      if (_disposed) {
        return;
      }

      _establecerError(error.mensaje);
      _notificar();
    } catch (_) {
      if (_disposed) {
        return;
      }

      _establecerError(
        'No pudimos preparar el carrito. '
        'Inténtalo nuevamente.',
      );
      _notificar();
    }
  }

  void incrementarCantidad() {
    if (!puedeMostrarControles || agregando || _disposed) {
      return;
    }

    _cantidad++;
    _prepararNuevaOperacion();
    _notificar();
  }

  void disminuirCantidad() {
    if (!puedeDisminuir || _disposed) {
      return;
    }

    _cantidad--;
    _prepararNuevaOperacion();
    _notificar();
  }

  Future<bool> agregarAlCarrito() async {
    if (_procesando || _disposed) {
      return false;
    }

    final productoActual = _producto;

    if (productoActual == null || productoActual.id <= 0) {
      _establecerError('No se encontró el producto.');
      _notificar();
      return false;
    }

    if (_cantidad <= 0) {
      _establecerError('La cantidad debe ser mayor que cero.');
      _notificar();
      return false;
    }

    final cantidadSolicitada = _cantidad;

    _procesando = true;
    _estado = AgregarCarritoEstado.agregando;
    _mensajeError = null;
    _mensajeExito = null;
    _notificar();

    try {
      // Se comprueba nuevamente inmediatamente antes del Repository.
      final sesion = await authRepository.obtenerSesion();

      if (_disposed) {
        return false;
      }

      _rolActual = sesion?.rol;
      _idUsuario = sesion?.idUsuario;

      if (sesion == null || sesion.rol != RolUsuario.cliente) {
        _estado = AgregarCarritoEstado.accesoNoAutorizado;
        _mensajeError = 'Tu sesión ya no permite realizar esta operación.';
        return false;
      }

      if (sesion.idUsuario <= 0) {
        throw const DatosCarritoInvalidosException(
          'No se pudo identificar al usuario del carrito.',
        );
      }

      final input = AgregarCarritoInput(
        idUsuario: sesion.idUsuario,
        producto: productoActual,
        cantidad: cantidadSolicitada,
        fecha: obtenerFechaActual(),
      );

      final carritoActualizado = await carritoRepository.agregarProducto(input);

      if (_disposed) {
        return false;
      }

      if (carritoActualizado.idUsuario != sesion.idUsuario ||
          carritoActualizado.buscarProducto(productoActual.id) == null) {
        throw const RespuestaCarritoInvalidaException();
      }

      _carrito = carritoActualizado;
      _estado = AgregarCarritoEstado.exito;
      _mensajeExito = 'Producto añadido a tu carrito.';
      _mensajeError = null;

      // La cantidad guardada permanece; solo se restablece el selector.
      _cantidad = 1;

      return true;
    } on CarritoException catch (error) {
      if (_disposed) {
        return false;
      }

      _establecerError(error.mensaje);
      return false;
    } catch (_) {
      if (_disposed) {
        return false;
      }

      _establecerError(
        'No pudimos agregar el producto. '
        'Inténtalo nuevamente.',
      );
      return false;
    } finally {
      _procesando = false;
      _notificar();
    }
  }

  void limpiarAvisos() {
    if (_disposed) {
      return;
    }

    _mensajeError = null;
    _mensajeExito = null;

    if (_rolActual == RolUsuario.cliente) {
      _estado = AgregarCarritoEstado.listo;
    }

    _notificar();
  }

  void _procesarCambioCarrito(CarritoSnapshot carritoActualizado) {
    if (_disposed || carritoActualizado.idUsuario != _idUsuario) {
      return;
    }

    _carrito = carritoActualizado;
    _notificar();
  }

  void _prepararNuevaOperacion() {
    _mensajeError = null;
    _mensajeExito = null;
    _estado = AgregarCarritoEstado.listo;
  }

  void _establecerError(String mensaje) {
    _mensajeError = mensaje;
    _mensajeExito = null;
    _estado = AgregarCarritoEstado.errorRecuperable;
  }

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _suscripcionCarrito?.cancel();
    super.dispose();
  }
}
