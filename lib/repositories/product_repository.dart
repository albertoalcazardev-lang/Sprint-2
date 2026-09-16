import '../models/actualizar_producto_input.dart';
import '../models/crear_producto_input.dart';
import '../models/producto.dart';

abstract class ProductRepository {
  Future<Producto> crearProducto(CrearProductoInput input);

  /// US07/E1 — Actualiza un producto existente.
  Future<Producto> actualizarProducto(ActualizarProductoInput input);

  Future<List<String>> obtenerCategorias();
}
