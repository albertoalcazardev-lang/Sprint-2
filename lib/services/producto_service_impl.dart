import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/producto.dart';
import 'producto_service.dart';

class ProductoServiceImpl implements ProductoService {
  final ApiClient apiClient;

  ProductoServiceImpl(this.apiClient);

  @override
  Future<List<Producto>> obtenerProductos() async {
    try {
      final response = await apiClient.dio.get('products');

      final datos = response.data as List<dynamic>;

      return datos
          .map(
            (producto) =>
                Producto.fromJson(Map<String, dynamic>.from(producto)),
          )
          .toList();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    try {
      final response = await apiClient.dio.get('products/categories');

      final datos = response.data as List<dynamic>;

      return datos.map((categoria) => categoria.toString()).toList();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    try {
      final response = await apiClient.dio.get('products/category/$categoria');

      final datos = response.data as List<dynamic>;

      return datos
          .map(
            (producto) =>
                Producto.fromJson(Map<String, dynamic>.from(producto)),
          )
          .toList();
    } on DioException {
      rethrow;
    }
  }
}
