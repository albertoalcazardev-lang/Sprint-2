import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/carrito_exception.dart';
import '../core/network/api_client.dart';
import '../models/agregar_carrito_input.dart';
import '../models/respuesta_carrito_model.dart';
import 'carrito_service.dart';

class CarritoServiceImpl implements CarritoService {
  final ApiClient apiClient;

  CarritoServiceImpl(this.apiClient);

  /// US09/E1-E2 — Envía POST /carts y valida la confirmación remota.
  @override
  Future<RespuestaCarritoModel> agregarProducto(
    AgregarCarritoInput input,
  ) async {
    try {
      _validarInput(input);

      final response = await apiClient.dio.post(
        ApiConstants.carts,
        data: {
          'userId': input.idUsuario,
          'date': _formatearFecha(input.fecha),
          'products': [
            {'productId': input.producto.id, 'quantity': input.cantidad},
          ],
        },
      );

      final datos = response.data;

      if (datos is! Map) {
        throw const RespuestaCarritoInvalidaException();
      }

      final respuesta = RespuestaCarritoModel.fromJson(
        Map<String, dynamic>.from(datos),
      );

      _validarRespuesta(respuesta: respuesta, input: input);

      return respuesta;
    } on DioException catch (error) {
      throw _convertirErrorDio(error);
    } on FormatException catch (error) {
      throw RespuestaCarritoInvalidaException(error.message);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const RespuestaCarritoInvalidaException();
    }
  }

  void _validarInput(AgregarCarritoInput input) {
    if (input.idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }

    if (input.producto.id <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }

    if (input.cantidad <= 0) {
      throw const DatosCarritoInvalidosException(
        'La cantidad debe ser mayor que cero.',
      );
    }
  }

  void _validarRespuesta({
    required RespuestaCarritoModel respuesta,
    required AgregarCarritoInput input,
  }) {
    if (respuesta.idUsuario != input.idUsuario) {
      throw const RespuestaCarritoInvalidaException(
        'La respuesta no corresponde al usuario autenticado.',
      );
    }

    final coincidencias = respuesta.productos.where(
      (producto) => producto.productoId == input.producto.id,
    );

    if (coincidencias.length != 1) {
      throw const RespuestaCarritoInvalidaException(
        'La respuesta no corresponde al producto agregado.',
      );
    }

    final productoConfirmado = coincidencias.single;

    if (productoConfirmado.cantidad != input.cantidad) {
      throw const RespuestaCarritoInvalidaException(
        'La respuesta contiene una cantidad diferente a la solicitada.',
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  CarritoException _convertirErrorDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return const SinConexionCarritoException();

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TiempoEsperaCarritoException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          return const CarritoException(
            'Tu sesión ya no permite realizar esta operación.',
          );
        }

        if (statusCode == 404) {
          return const CarritoException('No se encontró el producto.');
        }

        return const CarritoException(
          'No pudimos agregar el producto. '
          'Inténtalo nuevamente.',
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const CarritoException(
          'No pudimos agregar el producto. '
          'Inténtalo nuevamente.',
        );
    }
  }
}
