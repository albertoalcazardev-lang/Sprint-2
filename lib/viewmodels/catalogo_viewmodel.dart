import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class CatalogoViewModel extends ChangeNotifier {
  final ProductoRepository productoRepository;

  CatalogoViewModel(this.productoRepository);

  List<Producto> productos = [];

  bool estaCargando = false;

  String? mensajeError;

  Future<void> cargarProductos() async {
    estaCargando = true;
    mensajeError = null;
    notifyListeners();

    try {
      productos = await productoRepository.obtenerProductos();
    } catch (error) {
      productos = [];
      mensajeError = 'No pudimos cargar el catálogo.';
    } finally {
      estaCargando = false;
      notifyListeners();
    }
  }
}
