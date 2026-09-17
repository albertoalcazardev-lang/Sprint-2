import 'package:dio/dio.dart';

import '../core/errors/carrito_exception.dart';
import '../core/network/api_client.dart';
import '../models/carrito.dart';
import 'carrito_service.dart';

class CarritoServiceImpl implements CarritoService {
  final ApiClient apiClient;

  CarritoServiceImpl(this.apiClient);

  @override
  Future<List<Carrito>> obtenerCarritos() async {
    try {
      final response = await apiClient.dio.get('carts');
      final datos = response.data;

      if (datos is! List) {
        throw const CarritoException(
          'La respuesta del servidor no contiene una lista de carritos válida.',
        );
      }

      return datos
          .map(
            (carrito) => Carrito.fromJson(
              Map<String, dynamic>.from(carrito as Map),
            ),
          )
          .toList(growable: false);
    } on CarritoException {
      rethrow;
    } on DioException catch (error) {
      throw _convertirError(error);
    } on FormatException {
      throw const CarritoException(
        'No fue posible interpretar la información de los carritos.',
      );
    } catch (_) {
      throw const CarritoException(
        'No fue posible procesar el histórico de carritos.',
      );
    }
  }

  CarritoException _convertirError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const CarritoException(
        'Sin conexión. Revisa tu acceso a internet.',
      );
    }

    return const CarritoException(
      'No fue posible obtener el histórico de carritos.',
    );
  }
}
