class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://fakestoreapi.com/';

  static const String products = 'products';

  static const String productCategories = 'products/categories';

  /// Construye el endpoint para consultar o modificar un producto específico.
  static String productById(int id) {
    return '$products/$id';
  }
}
