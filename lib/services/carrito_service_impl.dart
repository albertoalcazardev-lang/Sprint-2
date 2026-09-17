import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/carrito_exception.dart';
import '../core/network/api_client.dart';
import '../models/agregar_carrito_input.dart';
import '../models/actualizar_carrito_input.dart';
import '../models/respuesta_carrito_model.dart';
import 'carrito_service.dart';
import 'gestion_carrito_service.dart';

class CarritoServiceImpl implements CarritoService, GestionCarritoService {
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

  /// US10/E2 — Envía el carrito local completo mediante PUT.
  @override
  Future<RespuestaCarritoModel> actualizarCarrito(
    ActualizarCarritoInput input,
  ) async {
    try {
      _validarActualizacion(input);

      final response = await apiClient.dio.put(
        ApiConstants.cartById(input.idCarrito),
        data: {
          'userId': input.idUsuario,
          'date': _formatearFecha(input.fecha),
          'products': input.items
              .map(
                (item) => {
                  'productId': item.producto.id,
                  'quantity': item.cantidad,
                },
              )
              .toList(),
        },
      );

      final respuesta = _decodificarRespuesta(response.data);

      if (respuesta.id != input.idCarrito ||
          respuesta.idUsuario != input.idUsuario) {
        throw const RespuestaCarritoInvalidaException(
          'La respuesta no corresponde al carrito actualizado.',
        );
      }

      final productosEsperados = {
        for (final item in input.items) item.producto.id: item.cantidad,
      };
      final productosRecibidos = {
        for (final item in respuesta.productos) item.productoId: item.cantidad,
      };

      if (productosEsperados.length != productosRecibidos.length ||
          productosEsperados.entries.any(
            (item) => productosRecibidos[item.key] != item.value,
          )) {
        throw const RespuestaCarritoInvalidaException(
          'La respuesta contiene líneas diferentes a las actualizadas.',
        );
      }

      return respuesta;
    } on DioException catch (error) {
      throw _convertirErrorDio(error, operacion: 'actualizar');
    } on FormatException catch (error) {
      throw RespuestaCarritoInvalidaException(error.message);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const RespuestaCarritoInvalidaException();
    }
  }

  /// US10/E3 — Fake Store elimina el carrito remoto completo; localmente se
  /// conserva el resto de líneas para representar la eliminación simulada.
  @override
  Future<RespuestaCarritoModel> eliminarCarrito(int idCarrito) async {
    try {
      if (idCarrito <= 0) {
        throw const DatosCarritoInvalidosException(
          'No se pudo identificar el carrito remoto.',
        );
      }

      final response = await apiClient.dio.delete(
        ApiConstants.cartById(idCarrito),
      );
      final respuesta = _decodificarRespuesta(response.data);

      if (respuesta.id != idCarrito) {
        throw const RespuestaCarritoInvalidaException(
          'La respuesta no corresponde al carrito eliminado.',
        );
      }

      return respuesta;
    } on DioException catch (error) {
      throw _convertirErrorDio(error, operacion: 'eliminar');
    } on FormatException catch (error) {
      throw RespuestaCarritoInvalidaException(error.message);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const RespuestaCarritoInvalidaException();
    }
  }

  RespuestaCarritoModel _decodificarRespuesta(dynamic datos) {
    if (datos is! Map) {
      throw const RespuestaCarritoInvalidaException();
    }

    return RespuestaCarritoModel.fromJson(Map<String, dynamic>.from(datos));
  }

  void _validarActualizacion(ActualizarCarritoInput input) {
    if (input.idCarrito <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar el carrito remoto.',
      );
    }

    if (input.idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }

    if (input.items.isEmpty ||
        input.items.any(
          (item) => item.producto.id <= 0 || item.cantidad <= 0,
        )) {
      throw const DatosCarritoInvalidosException(
        'El carrito contiene datos inválidos.',
      );
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

  CarritoException _convertirErrorDio(
    DioException error, {
    String operacion = 'agregar',
  }) {
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
          if (operacion == 'agregar') {
            return const CarritoException('No se encontró el producto.');
          }

          return const CarritoException(
            'No se encontró el carrito que intentas modificar.',
          );
        }

        return CarritoException(_mensajeOperacion(operacion));

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return CarritoException(_mensajeOperacion(operacion));
    }
  }

  String _mensajeOperacion(String operacion) {
    switch (operacion) {
      case 'actualizar':
        return 'No pudimos actualizar la cantidad. Inténtalo nuevamente.';
      case 'eliminar':
        return 'No pudimos eliminar el producto. Inténtalo nuevamente.';
      default:
        return 'No pudimos agregar el producto. Inténtalo nuevamente.';
    }
  }
}
