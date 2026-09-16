import '../models/producto.dart';

abstract class ProductoService {
  Future<List<Producto>> obtenerProductos();

  Future<List<String>> obtenerCategorias();

  Future<List<Producto>> obtenerProductosPorCategoria(String categoria);

  Future<Producto> obtenerProductoPorId(int id);

  Future<Producto> actualizarProducto(Producto producto);
}
