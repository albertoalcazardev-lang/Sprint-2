import '../models/producto.dart';

abstract class ProductoRepository {
  Future<List<Producto>> obtenerProductos();

  Future<List<String>> obtenerCategorias();

  Future<List<Producto>> obtenerProductosPorCategoria(String categoria);
}
