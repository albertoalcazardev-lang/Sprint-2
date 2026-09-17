import 'package:flutter/foundation.dart';

import '../core/errors/product_exception.dart';
import '../models/producto.dart';
import '../repositories/product_query_repository.dart';

class DetalleProductoViewModel extends ChangeNotifier {
  final ProductQueryRepository productRepository;

  DetalleProductoViewModel(this.productRepository);

  Producto? _producto;
  bool _cargando = false;
  String? _mensajeError;
  bool _disposed = false;

  Producto? get producto => _producto;
  bool get estaCargando => _cargando;
  String? get mensajeError => _mensajeError;

  Future<void> inicializar({
    required int productoId,
    Producto? productoInicial,
  }) async {
    if (_disposed) return;

    if (productoInicial != null && productoInicial.id == productoId) {
      _producto = productoInicial;
      _mensajeError = null;
      _notificar();
      return;
    }

    await cargarProducto(productoId);
  }

  Future<void> cargarProducto(int productoId) async {
    if (_disposed || _cargando) return;

    if (productoId <= 0) {
      _mensajeError = 'Producto no disponible.';
      _notificar();
      return;
    }

    _cargando = true;
    _mensajeError = null;
    _notificar();

    try {
      _producto = await productRepository.obtenerProductoPorId(productoId);
    } on ProductoException catch (error) {
      _producto = null;
      _mensajeError = error.mensaje;
    } catch (_) {
      _producto = null;
      _mensajeError = 'Producto no disponible.';
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  void aplicarProductoActualizado(Producto producto) {
    if (_disposed || _producto?.id != producto.id) return;

    _producto = producto;
    _mensajeError = null;
    _notificar();
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
