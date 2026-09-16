import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class DetalleProductoViewModel extends ChangeNotifier {
  final ProductoRepository productoRepository;

  DetalleProductoViewModel(this.productoRepository);

  Producto? producto;

  bool estaCargando = false;

  bool estaGuardando = false;

  String? mensajeError;

  String? mensajeExito;

  Future<void> cargarProducto(int id) async {
    estaCargando = true;
    mensajeError = null;
    mensajeExito = null;
    producto = null;
    notifyListeners();

    try {
      producto = await productoRepository.obtenerProductoPorId(id);
    } catch (error) {
      producto = null;
      mensajeError = 'Producto no disponible';
    } finally {
      estaCargando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarProducto(Producto productoActualizado) async {
    estaGuardando = true;
    mensajeError = null;
    mensajeExito = null;
    notifyListeners();

    try {
      final productoGuardado = await productoRepository.actualizarProducto(
        productoActualizado,
      );

      producto = productoGuardado;
      mensajeExito = 'Producto actualizado correctamente';

      return true;
    } catch (error) {
      mensajeError = 'No se pudo actualizar el producto.';
      return false;
    } finally {
      estaGuardando = false;
      notifyListeners();
    }
  }
}
