import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/carrito_exception.dart';
import '../core/network/api_client.dart';
import '../models/carrito.dart';
import 'historico_carrito_service.dart';

class HistoricoCarritoServiceImpl implements HistoricoCarritoService {
  final ApiClient apiClient;

  HistoricoCarritoServiceImpl(this.apiClient);

  @override
  Future<List<Carrito>> obtenerCarritos() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.carts);
      final datos = response.data;

      if (datos is! List) {
        throw const CarritoException(
          'La respuesta del servidor no contiene una lista de carritos válida.',
        );
      }

      return datos.map((carrito) {
        if (carrito is! Map) {
          throw const FormatException('Carrito inválido.');
        }

        return Carrito.fromJson(Map<String, dynamic>.from(carrito));
      }).toList(growable: false);
    } on CarritoException {
      rethrow;
    } on DioException catch (error) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          throw const SinConexionCarritoException();
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          throw const TiempoEsperaCarritoException();
        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          throw const CarritoException(
            'No fue posible obtener el histórico de carritos.',
          );
      }
    } on FormatException {
      throw const RespuestaCarritoInvalidaException(
        'No fue posible interpretar la información de los carritos.',
      );
    } catch (_) {
      throw const CarritoException(
        'No fue posible procesar el histórico de carritos.',
      );
    }
  }
}
