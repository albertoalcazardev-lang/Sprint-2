import 'package:flutter/foundation.dart';

import '../core/errors/product_exception.dart';
import '../core/validators/producto_validadores.dart';
import '../models/actualizar_producto_input.dart';
import '../models/producto.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/product_repository.dart';
import 'editar_producto_estado.dart';

/// US07/E1-E3 — Edición, validación y autorización de productos.
class EditarProductoViewModel extends ChangeNotifier {
  final ProductRepository productRepository;
  final AuthRepository authRepository;

  EditarProductoViewModel(this.productRepository, this.authRepository);

  EditarProductoEstado _estado = EditarProductoEstado.inicial;
  Producto? _productoOriginal;
  Producto? _productoActualizado;
  List<String> _categorias = const [];

  String? _mensajeError;
  String? _mensajeErrorCategorias;
  String? _mensajeExito;

  bool _cargandoCategorias = false;
  bool _procesandoActualizacion = false;
  bool _disposed = false;

  EditarProductoEstado get estado => _estado;

  Producto? get productoOriginal => _productoOriginal;

  Producto? get productoActualizado => _productoActualizado;

  List<String> get categorias => List.unmodifiable(_categorias);

  String? get mensajeError => _mensajeError;

  String? get mensajeErrorCategorias => _mensajeErrorCategorias;

  String? get mensajeExito => _mensajeExito;

  bool get cargandoCategorias => _cargandoCategorias;

  bool get enviandoCambios => _procesandoActualizacion;

  bool get accesoNoAutorizado =>
      _estado == EditarProductoEstado.accesoNoAutorizado;

  bool get formularioListo =>
      _productoOriginal != null &&
      _categorias.isNotEmpty &&
      !accesoNoAutorizado;

  bool get puedeGuardar =>
      formularioListo && !_cargandoCategorias && !_procesandoActualizacion;

  Future<void> inicializar(Producto producto) async {
    if (_estado != EditarProductoEstado.inicial) {
      return;
    }

    _estado = EditarProductoEstado.comprobandoAcceso;
    _mensajeError = null;
    _mensajeErrorCategorias = null;
    _mensajeExito = null;
    _notificar();

    final esAdministrador = await _esAdministrador();

    if (_disposed) {
      return;
    }

    if (!esAdministrador) {
      _establecerAccesoNoAutorizado();
      return;
    }

    if (producto.id <= 0) {
      _mensajeError = 'No se encontró el producto que intentas editar.';
      _estado = EditarProductoEstado.errorRecuperable;
      _notificar();
      return;
    }

    _productoOriginal = producto;

    await cargarCategorias();
  }

  Future<void> cargarCategorias() async {
    if (_cargandoCategorias || _procesandoActualizacion || _disposed) {
      return;
    }

    final producto = _productoOriginal;

    if (producto == null) {
      _mensajeError = 'No se encontró el producto que intentas editar.';
      _estado = EditarProductoEstado.errorRecuperable;
      _notificar();
      return;
    }

    final esAdministrador = await _esAdministrador();

    if (_disposed) {
      return;
    }

    if (!esAdministrador) {
      _establecerAccesoNoAutorizado();
      return;
    }

    _cargandoCategorias = true;
    _mensajeErrorCategorias = null;
    _estado = EditarProductoEstado.cargandoCategorias;
    _notificar();

    try {
      final categoriasObtenidas = await productRepository.obtenerCategorias();

      if (_disposed) {
        return;
      }

      final categoriasNormalizadas = categoriasObtenidas
          .map((categoria) => categoria.trim())
          .where((categoria) => categoria.isNotEmpty)
          .toSet()
          .toList(growable: true);

      final categoriaActual = producto.categoria.trim();

      if (categoriaActual.isNotEmpty &&
          !categoriasNormalizadas.contains(categoriaActual)) {
        categoriasNormalizadas.insert(0, categoriaActual);
      }

      if (categoriasNormalizadas.isEmpty) {
        throw const ProductoException('No pudimos cargar las categorías.');
      }

      _categorias = List.unmodifiable(categoriasNormalizadas);
      _estado = EditarProductoEstado.formularioListo;
    } on ProductoException catch (error) {
      if (_disposed) {
        return;
      }

      _mensajeErrorCategorias = error.mensaje;
      _estado = EditarProductoEstado.errorRecuperable;
    } catch (_) {
      if (_disposed) {
        return;
      }

      _mensajeErrorCategorias = 'No pudimos cargar las categorías.';
      _estado = EditarProductoEstado.errorRecuperable;
    } finally {
      _cargandoCategorias = false;
      _notificar();
    }
  }

  Future<bool> actualizarProducto({
    required String titulo,
    required String precio,
    required String? categoria,
    required String descripcion,
  }) async {
    if (_procesandoActualizacion || _disposed) {
      return false;
    }

    final formularioValido = ProductoValidadores.esFormularioEdicionValido(
      titulo: titulo,
      precio: precio,
      categoria: categoria,
      descripcion: descripcion,
    );

    if (!formularioValido) {
      _mensajeError = 'Revisa los campos marcados antes de continuar.';
      _mensajeExito = null;
      _productoActualizado = null;
      _estado = EditarProductoEstado.formularioListo;
      _notificar();
      return false;
    }

    final producto = _productoOriginal;

    if (producto == null || producto.id <= 0) {
      _mensajeError = 'No se encontró el producto que intentas editar.';
      _mensajeExito = null;
      _productoActualizado = null;
      _estado = EditarProductoEstado.errorRecuperable;
      _notificar();
      return false;
    }

    if (ProductoValidadores.validarImageUrl(producto.imageUrl) != null) {
      _mensajeError = 'La información original del producto no es válida.';
      _mensajeExito = null;
      _productoActualizado = null;
      _estado = EditarProductoEstado.errorRecuperable;
      _notificar();
      return false;
    }

    _procesandoActualizacion = true;
    _mensajeError = null;
    _mensajeExito = null;
    _productoActualizado = null;
    _estado = EditarProductoEstado.enviandoCambios;
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

      final input = ActualizarProductoInput(
        id: producto.id,
        titulo: titulo.trim(),
        precio: ProductoValidadores.convertirPrecio(precio),
        categoria: categoria!.trim(),
        imageUrl: producto.imageUrl.trim(),
        descripcion: descripcion.trim(),
      );

      final respuesta = await productRepository.actualizarProducto(input);

      if (_disposed) {
        return false;
      }

      _productoActualizado = Producto(
        id: respuesta.id,
        titulo: respuesta.titulo,
        precio: respuesta.precio,
        categoria: respuesta.categoria,
        imageUrl: producto.imageUrl,
        descripcion: respuesta.descripcion,
      );

      _mensajeExito = 'Producto actualizado (Simulación)';
      _estado = EditarProductoEstado.productoActualizado;

      return true;
    } on ProductoException catch (error) {
      if (_disposed) {
        return false;
      }

      _mensajeError = error.mensaje;
      _estado = EditarProductoEstado.errorRecuperable;
      return false;
    } catch (_) {
      if (_disposed) {
        return false;
      }

      _mensajeError =
          'No pudimos actualizar el producto. Inténtalo nuevamente.';
      _estado = EditarProductoEstado.errorRecuperable;
      return false;
    } finally {
      _procesandoActualizacion = false;
      _notificar();
    }
  }

  void registrarEdicion() {
    if (_mensajeError == null || _disposed) {
      return;
    }

    _mensajeError = null;

    if (formularioListo) {
      _estado = EditarProductoEstado.formularioListo;
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
    _mensajeError = 'No tienes acceso a esta sección.';
    _mensajeErrorCategorias = null;
    _mensajeExito = null;
    _productoActualizado = null;
    _estado = EditarProductoEstado.accesoNoAutorizado;

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
