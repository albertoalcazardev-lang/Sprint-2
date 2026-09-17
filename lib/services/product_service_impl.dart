import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/product_exception.dart';
import '../core/network/api_client.dart';
import '../models/actualizar_producto_input.dart';
import '../models/crear_producto_input.dart';
import '../models/producto_model.dart';
import 'product_service.dart';
import 'product_query_service.dart';

class ProductServiceImpl implements ProductService, ProductQueryService {
  final ApiClient apiClient;

  ProductServiceImpl(this.apiClient);

  @override
  Future<List<ProductoModel>> obtenerProductos() {
    return _obtenerLista(ApiConstants.products);
  }

  @override
  Future<ProductoModel> obtenerProductoPorId(int productoId) async {
    if (productoId <= 0) {
      throw const ProductoException('No se encontró el producto.');
    }

    try {
      final response = await apiClient.dio.get(
        ApiConstants.productById(productoId),
      );
      final datos = response.data;

      if (datos is! Map) {
        throw const RespuestaProductoInvalidaException();
      }

      final producto = ProductoModel.fromJson(Map<String, dynamic>.from(datos));

      if (producto.id != productoId) {
        throw const RespuestaProductoInvalidaException(
          'La respuesta no corresponde al producto solicitado.',
        );
      }

      return producto;
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado: 'No pudimos cargar el producto.',
        mensajeNoEncontrado: 'No se encontró el producto.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException();
    }
  }

  @override
  Future<List<ProductoModel>> obtenerProductosPorCategoria(String categoria) {
    final categoriaNormalizada = categoria.trim();

    if (categoriaNormalizada.isEmpty) {
      throw const ProductoException('Selecciona una categoría válida.');
    }

    return _obtenerLista(ApiConstants.productsByCategory(categoriaNormalizada));
  }

  @override
  Future<ProductoModel> crearProducto(CrearProductoInput input) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.products,
        data: {
          'title': input.titulo,
          'price': input.precio,
          'category': input.categoria,
          'image': input.imageUrl,
          'description': input.descripcion,
        },
      );

      final datos = response.data;

      if (datos is! Map) {
        throw const RespuestaProductoInvalidaException();
      }

      return ProductoModel.fromJson(Map<String, dynamic>.from(datos));
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado:
            'No pudimos crear el producto. Inténtalo nuevamente.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException();
    }
  }

  /// US07/E1 — Envía PUT /products/{id} y procesa el producto actualizado.
  @override
  Future<ProductoModel> actualizarProducto(
    ActualizarProductoInput input,
  ) async {
    try {
      if (input.id <= 0) {
        throw const ProductoException(
          'No se encontró el producto que intentas editar.',
        );
      }

      final response = await apiClient.dio.put(
        ApiConstants.productById(input.id),
        data: {
          'title': input.titulo.trim(),
          'price': input.precio,
          'category': input.categoria.trim(),
          'image': input.imageUrl.trim(),
          'description': input.descripcion.trim(),
        },
      );

      final datos = response.data;

      if (datos is! Map) {
        throw const RespuestaProductoInvalidaException();
      }

      final json = Map<String, dynamic>.from(datos);
      final imagenDevuelta = json['image'];

      if (imagenDevuelta is! String || imagenDevuelta.trim().isEmpty) {
        json['image'] = input.imageUrl.trim();
      }

      final productoActualizado = ProductoModel.fromJson(json);

      if (productoActualizado.id != input.id) {
        throw const RespuestaProductoInvalidaException(
          'La respuesta del servidor no corresponde al producto actualizado.',
        );
      }

      return productoActualizado;
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado:
            'No pudimos actualizar el producto. Inténtalo nuevamente.',
        mensajeNoEncontrado: 'No se encontró el producto que intentas editar.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException();
    }
  }

  /// US08/E1 — Envía DELETE /products/{id} y valida la respuesta.
  @override
  Future<ProductoModel> eliminarProducto(int productoId) async {
    try {
      if (productoId <= 0) {
        throw const ProductoException(
          'No se encontró el producto que intentas eliminar.',
        );
      }

      final response = await apiClient.dio.delete(
        ApiConstants.productById(productoId),
      );

      final datos = response.data;

      if (datos is! Map) {
        throw const RespuestaProductoInvalidaException();
      }

      final productoEliminado = ProductoModel.fromJson(
        Map<String, dynamic>.from(datos),
      );

      if (productoEliminado.id != productoId) {
        throw const RespuestaProductoInvalidaException(
          'La respuesta del servidor no corresponde '
          'al producto eliminado.',
        );
      }

      return productoEliminado;
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado:
            'No pudimos eliminar el producto. '
            'Inténtalo nuevamente.',
        mensajeNoEncontrado:
            'No se encontró el producto que intentas eliminar.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException();
    }
  }

  @override
  Future<List<String>> obtenerCategorias() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.productCategories);

      final datos = response.data;

      if (datos is! List) {
        throw const RespuestaProductoInvalidaException(
          'No pudimos interpretar las categorías.',
        );
      }

      final categorias = datos
          .map((categoria) {
            if (categoria is! String || categoria.trim().isEmpty) {
              throw const FormatException(
                'La respuesta contiene una categoría inválida.',
              );
            }

            return categoria.trim();
          })
          .toList(growable: false);

      if (categorias.isEmpty) {
        throw const RespuestaProductoInvalidaException(
          'La lista de categorías está vacía.',
        );
      }

      return categorias;
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado: 'No pudimos cargar las categorías.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException(
        'No pudimos interpretar las categorías.',
      );
    }
  }

  Future<List<ProductoModel>> _obtenerLista(String endpoint) async {
    try {
      final response = await apiClient.dio.get(endpoint);
      final datos = response.data;

      if (datos is! List) {
        throw const RespuestaProductoInvalidaException(
          'No pudimos interpretar el catálogo.',
        );
      }

      return datos
          .map((producto) {
            if (producto is! Map) {
              throw const FormatException(
                'El catálogo contiene datos inválidos.',
              );
            }

            return ProductoModel.fromJson(Map<String, dynamic>.from(producto));
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw _convertirErrorDio(
        error,
        mensajePredeterminado: 'No pudimos cargar el catálogo.',
      );
    } on FormatException catch (error) {
      throw RespuestaProductoInvalidaException(error.message);
    } on ProductoException {
      rethrow;
    } catch (_) {
      throw const RespuestaProductoInvalidaException(
        'No pudimos interpretar el catálogo.',
      );
    }
  }

  ProductoException _convertirErrorDio(
    DioException error, {
    required String mensajePredeterminado,
    String? mensajeNoEncontrado,
  }) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return const SinConexionProductoException();

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TiempoEsperaProductoException();

      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404 && mensajeNoEncontrado != null) {
          return ProductoException(mensajeNoEncontrado);
        }

        return ProductoException(mensajePredeterminado);

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return ProductoException(mensajePredeterminado);
    }
  }
}
