class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://fakestoreapi.com/';

  static const String products = 'products';

  static const String productCategories = 'products/categories';

  /// US09/E1-E2 — Creación simulada de carritos.
  static const String carts = 'carts';

  /// US10/E2-E3 — Actualización o eliminación del carrito remoto simulado.
  static String cartById(int id) {
    return '$carts/$id';
  }

  /// Construye el endpoint para consultar o modificar un producto específico.
  static String productById(int id) {
    return '$products/$id';
  }
}
