import '../models/producto.dart';

abstract class ProductQueryRepository {
  Future<List<String>> obtenerCategorias();

  Future<List<Producto>> obtenerProductos();

  Future<Producto> obtenerProductoPorId(int productoId);

  Future<List<Producto>> obtenerProductosPorCategoria(String categoria);
}
