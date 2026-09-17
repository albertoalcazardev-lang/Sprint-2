import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class CatalogoViewModel extends ChangeNotifier {
  final ProductoRepository productoRepository;

  CatalogoViewModel(this.productoRepository);

  List<Producto> productos = [];

  List<String> categorias = [];

  String? categoriaSeleccionada;

  bool estaCargando = false;

  String? mensajeError;

  Future<void> cargarProductos() async {
    estaCargando = true;
    mensajeError = null;
    productos = [];
    categoriaSeleccionada = null;
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

  Future<void> cargarCategorias() async {
    try {
      categorias = await productoRepository.obtenerCategorias();
      notifyListeners();
    } catch (error) {
      categorias = [];
      notifyListeners();
    }
  }

  Future<void> filtrarPorCategoria(String categoria) async {
    estaCargando = true;
    mensajeError = null;
    productos = [];
    categoriaSeleccionada = categoria;
    notifyListeners();

    try {
      productos = await productoRepository.obtenerProductosPorCategoria(
        categoria,
      );
    } catch (error) {
      productos = [];
      mensajeError = 'No pudimos cargar los productos de esta categoría.';
    } finally {
      estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> mostrarTodos() async {
    await cargarProductos();
  }
}
