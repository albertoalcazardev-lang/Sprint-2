import '../models/producto_model.dart';

abstract class ProductQueryService {
  Future<List<ProductoModel>> obtenerProductos();

  Future<ProductoModel> obtenerProductoPorId(int productoId);

  Future<List<ProductoModel>> obtenerProductosPorCategoria(String categoria);
}
