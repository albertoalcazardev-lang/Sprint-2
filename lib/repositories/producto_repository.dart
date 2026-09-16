import '../models/producto.dart';

abstract class ProductoRepository {
  Future<List<Producto>> obtenerProductos();
}
