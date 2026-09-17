import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/constants/api_constants.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/core/network/api_client.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/services/carrito_service.dart';
import 'package:tienda_flutter/services/carrito_service_impl.dart';

void main() {
  late ApiClient apiClient;
  late InterceptorCarrito interceptor;
  late CarritoService carritoService;

  const producto = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila con compartimento para portátil.',
  );

  setUp(() {
    apiClient = ApiClient();
    interceptor = InterceptorCarrito(datosRespuesta: _respuestaValida());

    apiClient.dio.interceptors.add(interceptor);

    carritoService = CarritoServiceImpl(apiClient);
  });

  tearDown(() {
    apiClient.dio.close(force: true);
  });

  AgregarCarritoInput crearInput({
    int idUsuario = 4,
    Producto productoSeleccionado = producto,
    int cantidad = 2,
  }) {
    return AgregarCarritoInput(
      idUsuario: idUsuario,
      producto: productoSeleccionado,
      cantidad: cantidad,
      fecha: DateTime(2026, 9, 17, 22, 45),
    );
  }

  test('utiliza POST /carts con el cuerpo correcto', () async {
    await carritoService.agregarProducto(crearInput());

    final solicitud = interceptor.ultimaSolicitud;

    expect(solicitud, isNotNull);
    expect(solicitud!.method, 'POST');
    expect(solicitud.path, ApiConstants.carts);

    final cuerpo = Map<String, dynamic>.from(solicitud.data as Map);

    expect(cuerpo['userId'], 4);
    expect(cuerpo['date'], '2026-09-17');

    final productos = cuerpo['products'] as List<dynamic>;

    expect(productos, hasLength(1));

    final productoEnviado = Map<String, dynamic>.from(productos.single as Map);

    expect(productoEnviado['productId'], 1);
    expect(productoEnviado['quantity'], 2);

    expect(productoEnviado.containsKey('title'), isFalse);
    expect(productoEnviado.containsKey('price'), isFalse);
    expect(productoEnviado.containsKey('image'), isFalse);
    expect(productoEnviado.containsKey('category'), isFalse);
  });

  test('convierte una respuesta válida', () async {
    final respuesta = await carritoService.agregarProducto(crearInput());

    expect(respuesta.id, 21);
    expect(respuesta.idUsuario, 4);
    expect(respuesta.fecha, DateTime(2026, 9, 17));
    expect(respuesta.productos, hasLength(1));
    expect(respuesta.productos.single.productoId, 1);
    expect(respuesta.productos.single.cantidad, 2);
  });

  test('rechaza userId inválido sin ejecutar POST', () async {
    await expectLater(
      carritoService.agregarProducto(crearInput(idUsuario: 0)),
      throwsA(isA<DatosCarritoInvalidosException>()),
    );

    expect(interceptor.ultimaSolicitud, isNull);
  });

  test('rechaza productId inválido sin ejecutar POST', () async {
    const productoInvalido = Producto(
      id: 0,
      titulo: 'Producto inválido',
      precio: 10,
      categoria: 'electronics',
      imageUrl: 'https://ejemplo.com/producto.jpg',
      descripcion: 'Descripción del producto.',
    );

    await expectLater(
      carritoService.agregarProducto(
        crearInput(productoSeleccionado: productoInvalido),
      ),
      throwsA(isA<DatosCarritoInvalidosException>()),
    );

    expect(interceptor.ultimaSolicitud, isNull);
  });

  test('rechaza cantidad inválida sin ejecutar POST', () async {
    await expectLater(
      carritoService.agregarProducto(crearInput(cantidad: 0)),
      throwsA(isA<DatosCarritoInvalidosException>()),
    );

    expect(interceptor.ultimaSolicitud, isNull);
  });

  test('rechaza una respuesta que no es un objeto JSON', () async {
    interceptor.datosRespuesta = const ['respuesta', 'inválida'];

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(isA<RespuestaCarritoInvalidaException>()),
    );
  });

  test('rechaza una respuesta con otro usuario', () async {
    interceptor.datosRespuesta = {..._respuestaValida(), 'userId': 99};

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(
        isA<RespuestaCarritoInvalidaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('usuario'),
        ),
      ),
    );
  });

  test('rechaza una respuesta con otro producto', () async {
    interceptor.datosRespuesta = {
      ..._respuestaValida(),
      'products': [
        {'productId': 99, 'quantity': 2},
      ],
    };

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(
        isA<RespuestaCarritoInvalidaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('producto'),
        ),
      ),
    );
  });

  test('rechaza una cantidad diferente a la solicitada', () async {
    interceptor.datosRespuesta = {
      ..._respuestaValida(),
      'products': [
        {'productId': 1, 'quantity': 8},
      ],
    };

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(
        isA<RespuestaCarritoInvalidaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('cantidad'),
        ),
      ),
    );
  });

  test('rechaza una respuesta sin productos', () async {
    interceptor.datosRespuesta = {
      ..._respuestaValida(),
      'products': <dynamic>[],
    };

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(isA<RespuestaCarritoInvalidaException>()),
    );
  });

  test('convierte HTTP 404 en producto no encontrado', () async {
    interceptor.codigoEstado = 404;
    interceptor.datosRespuesta = {'message': 'Product not found'};

    await expectLater(
      carritoService.agregarProducto(crearInput()),
      throwsA(
        isA<CarritoException>().having(
          (error) => error.mensaje,
          'mensaje',
          'No se encontró el producto.',
        ),
      ),
    );
  });
}

Map<String, dynamic> _respuestaValida() {
  return {
    'id': 21,
    'userId': 4,
    'date': '2026-09-17',
    'products': [
      {'productId': 1, 'quantity': 2},
    ],
  };
}

class InterceptorCarrito extends Interceptor {
  RequestOptions? ultimaSolicitud;
  Object? datosRespuesta;
  int codigoEstado;

  InterceptorCarrito({required this.datosRespuesta, this.codigoEstado = 200});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    ultimaSolicitud = options;

    final respuesta = Response<dynamic>(
      requestOptions: options,
      data: datosRespuesta,
      statusCode: codigoEstado,
    );

    if (codigoEstado >= 400) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: respuesta,
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.resolve(respuesta);
  }
}
