import '../models/producto.dart';

abstract class ProductoService {
  Future<List<Producto>> obtenerProductos();

  Future<List<String>> obtenerCategorias();

  Future<List<Producto>> obtenerProductosPorCategoria(String categoria);
}
