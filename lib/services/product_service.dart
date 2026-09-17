import '../models/actualizar_producto_input.dart';
import '../models/crear_producto_input.dart';
import '../models/producto_model.dart';

abstract class ProductService {
  Future<ProductoModel> crearProducto(CrearProductoInput input);

  /// US07/E1 — Actualiza un producto existente mediante PUT.
  Future<ProductoModel> actualizarProducto(ActualizarProductoInput input);

  /// US08/E1 — Elimina de forma simulada un producto mediante DELETE.
  Future<ProductoModel> eliminarProducto(int productoId);

  Future<List<String>> obtenerCategorias();
}
