import 'package:flutter/foundation.dart';

import '../core/errors/product_exception.dart';
import '../core/validators/producto_validadores.dart';
import '../models/crear_producto_input.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/product_repository.dart';
import 'crear_producto_estado.dart';

/// US06/E1, E2 y E3 — P17, P18, P19 y protección de la operación.
class CrearProductoViewModel extends ChangeNotifier {
  final ProductRepository productRepository;
  final AuthRepository authRepository;

  CrearProductoViewModel(this.productRepository, this.authRepository);

  CrearProductoEstado _estado = CrearProductoEstado.inicial;
  List<String> _categorias = const [];
  String? _mensajeError;
  String? _mensajeErrorCategorias;
  String? _mensajeExito;
  int? _idProductoCreado;

  bool _cargandoCategorias = false;
  bool _procesandoCreacion = false;

  CrearProductoEstado get estado => _estado;

  List<String> get categorias => List.unmodifiable(_categorias);

  String? get mensajeError => _mensajeError;

  String? get mensajeErrorCategorias => _mensajeErrorCategorias;

  String? get mensajeExito => _mensajeExito;

  int? get idProductoCreado => _idProductoCreado;

  bool get cargandoCategorias => _cargandoCategorias;

  bool get enviandoProducto => _procesandoCreacion;

  bool get accesoNoAutorizado =>
      _estado == CrearProductoEstado.accesoNoAutorizado;

  bool get puedeGuardar =>
      !_procesandoCreacion &&
      !_cargandoCategorias &&
      _categorias.isNotEmpty &&
      !accesoNoAutorizado;

  Future<void> inicializar() async {
    if (_estado != CrearProductoEstado.inicial) {
      return;
    }

    await cargarCategorias();
  }

  Future<void> cargarCategorias() async {
    if (_cargandoCategorias || _procesandoCreacion) {
      return;
    }

    final esAdministrador = await _esAdministrador();

    if (!esAdministrador) {
      _establecerAccesoNoAutorizado();
      return;
    }

    _cargandoCategorias = true;
    _estado = CrearProductoEstado.cargandoCategorias;
    _mensajeErrorCategorias = null;
    notifyListeners();

    try {
      final categoriasObtenidas = await productRepository.obtenerCategorias();

      if (categoriasObtenidas.isEmpty) {
        throw const ProductoException('No pudimos cargar las categorías.');
      }

      _categorias = categoriasObtenidas;
      _estado = CrearProductoEstado.formularioListo;
    } on ProductoException catch (error) {
      _mensajeErrorCategorias = error.mensaje;
      _estado = CrearProductoEstado.errorRecuperable;
    } catch (_) {
      _mensajeErrorCategorias = 'No pudimos cargar las categorías.';
      _estado = CrearProductoEstado.errorRecuperable;
    } finally {
      _cargandoCategorias = false;
      notifyListeners();
    }
  }

  Future<bool> crearProducto({
    required String titulo,
    required String precio,
    required String? categoria,
    required String imageUrl,
    required String descripcion,
  }) async {
    if (_procesandoCreacion) {
      return false;
    }

    final formularioValido = ProductoValidadores.esFormularioValido(
      titulo: titulo,
      precio: precio,
      categoria: categoria,
      imageUrl: imageUrl,
      descripcion: descripcion,
    );

    if (!formularioValido) {
      _mensajeError = 'Revisa los campos marcados antes de continuar.';
      _mensajeExito = null;
      _idProductoCreado = null;
      _estado = CrearProductoEstado.formularioListo;
      notifyListeners();
      return false;
    }

    _procesandoCreacion = true;
    _mensajeError = null;
    _mensajeExito = null;
    _idProductoCreado = null;
    _estado = CrearProductoEstado.enviandoProducto;
    notifyListeners();

    try {
      final esAdministrador = await _esAdministrador();

      if (!esAdministrador) {
        _establecerAccesoNoAutorizado(notificar: false);
        return false;
      }

      final input = CrearProductoInput(
        titulo: titulo.trim(),
        precio: ProductoValidadores.convertirPrecio(precio),
        categoria: categoria!.trim(),
        imageUrl: imageUrl.trim(),
        descripcion: descripcion.trim(),
      );

      final producto = await productRepository.crearProducto(input);

      _idProductoCreado = producto.id;
      _mensajeExito =
          'Producto creado (Simulación). ID generado: ${producto.id}';
      _estado = CrearProductoEstado.productoCreado;

      return true;
    } on ProductoException catch (error) {
      _mensajeError = error.mensaje;
      _estado = CrearProductoEstado.errorRecuperable;
      return false;
    } catch (_) {
      _mensajeError = 'No pudimos crear el producto. Inténtalo nuevamente.';
      _estado = CrearProductoEstado.errorRecuperable;
      return false;
    } finally {
      _procesandoCreacion = false;
      notifyListeners();
    }
  }

  void registrarEdicion() {
    final habiaResultadoAnterior =
        _mensajeExito != null ||
        _mensajeError != null ||
        _idProductoCreado != null;

    if (!habiaResultadoAnterior) {
      return;
    }

    _mensajeExito = null;
    _mensajeError = null;
    _idProductoCreado = null;

    if (_categorias.isNotEmpty) {
      _estado = CrearProductoEstado.formularioListo;
    }

    notifyListeners();
  }

  void limpiarError() {
    if (_mensajeError == null) {
      return;
    }

    _mensajeError = null;

    if (_categorias.isNotEmpty) {
      _estado = CrearProductoEstado.formularioListo;
    }

    notifyListeners();
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
    _mensajeExito = null;
    _idProductoCreado = null;
    _estado = CrearProductoEstado.accesoNoAutorizado;

    if (notificar) {
      notifyListeners();
    }
  }
}
