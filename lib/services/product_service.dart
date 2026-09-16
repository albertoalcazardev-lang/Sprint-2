import '../models/actualizar_producto_input.dart';
import '../models/crear_producto_input.dart';
import '../models/producto_model.dart';

abstract class ProductService {
  Future<ProductoModel> crearProducto(CrearProductoInput input);

  /// US07/E1 — Actualiza un producto existente mediante PUT.
  Future<ProductoModel> actualizarProducto(ActualizarProductoInput input);

  Future<List<String>> obtenerCategorias();
}
