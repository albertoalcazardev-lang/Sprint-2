import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/errors/carrito_exception.dart';
import 'package:tienda_flutter/data_sources/carrito_local_data_source.dart';
import 'package:tienda_flutter/models/agregar_carrito_input.dart';
import 'package:tienda_flutter/models/carrito_snapshot.dart';
import 'package:tienda_flutter/models/item_carrito.dart';
import 'package:tienda_flutter/models/producto.dart';
import 'package:tienda_flutter/models/producto_carrito_respuesta_model.dart';
import 'package:tienda_flutter/models/respuesta_carrito_model.dart';
import 'package:tienda_flutter/repositories/carrito_repository.dart';
import 'package:tienda_flutter/repositories/carrito_repository_impl.dart';
import 'package:tienda_flutter/services/carrito_service.dart';

void main() {
  late List<String> ordenOperaciones;
  late FakeCarritoService carritoService;
  late FakeCarritoLocalDataSource localDataSource;
  late CarritoRepository repository;

  const producto = Producto(
    id: 1,
    titulo: 'Mochila urbana',
    precio: 109.95,
    categoria: "men's clothing",
    imageUrl: 'https://ejemplo.com/mochila.jpg',
    descripcion: 'Mochila con compartimento para portátil.',
  );

  setUp(() {
    ordenOperaciones = [];

    carritoService = FakeCarritoService(ordenOperaciones: ordenOperaciones);

    localDataSource = FakeCarritoLocalDataSource(
      ordenOperaciones: ordenOperaciones,
      carritoRespuesta: CarritoSnapshot(
        idUsuario: 4,
        items: const [ItemCarrito(producto: producto, cantidad: 2)],
      ),
    );

    repository = CarritoRepositoryImpl(carritoService, localDataSource);
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
      fecha: DateTime(2026, 9, 17),
    );
  }

  test('ejecuta primero el POST y después la actualización local', () async {
    await repository.agregarProducto(crearInput());

    expect(ordenOperaciones, ['remoto', 'local']);
  });

  test('envía los datos correctos a Service y fuente local', () async {
    final input = crearInput(cantidad: 3);

    await repository.agregarProducto(input);

    expect(carritoService.llamadasAgregar, 1);
    expect(carritoService.ultimoInput, same(input));

    expect(localDataSource.llamadasAgregar, 1);
    expect(localDataSource.ultimoIdUsuario, 4);
    expect(localDataSource.ultimoProducto, same(producto));
    expect(localDataSource.ultimaCantidad, 3);
  });

  test('devuelve el carrito producido por la fuente local', () async {
    final carrito = await repository.agregarProducto(crearInput());

    expect(carrito, same(localDataSource.carritoRespuesta));

    expect(carrito.idUsuario, 4);
    expect(carrito.totalUnidades, 2);
  });

  test('un fallo remoto no modifica el carrito local', () async {
    carritoService.errorAlAgregar = const SinConexionCarritoException();

    await expectLater(
      repository.agregarProducto(crearInput()),
      throwsA(isA<SinConexionCarritoException>()),
    );

    expect(carritoService.llamadasAgregar, 1);
    expect(localDataSource.llamadasAgregar, 0);
    expect(ordenOperaciones, ['remoto']);
  });

  test('un fallo local no genera una confirmación falsa', () async {
    localDataSource.errorAlAgregar = const PersistenciaCarritoException();

    await expectLater(
      repository.agregarProducto(crearInput()),
      throwsA(isA<PersistenciaCarritoException>()),
    );

    expect(carritoService.llamadasAgregar, 1);
    expect(localDataSource.llamadasAgregar, 1);
    expect(ordenOperaciones, ['remoto', 'local']);
  });

  test('rechaza un usuario inválido antes del Service', () async {
    await expectLater(
      repository.agregarProducto(crearInput(idUsuario: 0)),
      throwsA(isA<DatosCarritoInvalidosException>()),
    );

    expect(carritoService.llamadasAgregar, 0);
    expect(localDataSource.llamadasAgregar, 0);
  });

  test('rechaza una cantidad inválida antes del Service', () async {
    await expectLater(
      repository.agregarProducto(crearInput(cantidad: 0)),
      throwsA(isA<DatosCarritoInvalidosException>()),
    );

    expect(carritoService.llamadasAgregar, 0);
    expect(localDataSource.llamadasAgregar, 0);
  });

  test('obtenerCarritoActual delega el usuario correcto', () async {
    final carrito = await repository.obtenerCarritoActual(4);

    expect(localDataSource.llamadasObtener, 1);
    expect(localDataSource.ultimoIdUsuario, 4);
    expect(carrito, same(localDataSource.carritoRespuesta));
  });

  test('limpiarCarrito delega únicamente el usuario indicado', () async {
    await repository.limpiarCarrito(7);

    expect(localDataSource.llamadasLimpiar, 1);
    expect(localDataSource.ultimoIdUsuario, 7);
  });

  test('observarCarrito utiliza el ID solicitado', () {
    repository.observarCarrito(4);

    expect(localDataSource.llamadasObservar, 1);
    expect(localDataSource.ultimoIdUsuario, 4);
  });
}

class FakeCarritoService implements CarritoService {
  final List<String> ordenOperaciones;

  int llamadasAgregar = 0;
  AgregarCarritoInput? ultimoInput;
  CarritoException? errorAlAgregar;

  FakeCarritoService({required this.ordenOperaciones});

  @override
  Future<RespuestaCarritoModel> agregarProducto(
    AgregarCarritoInput input,
  ) async {
    llamadasAgregar++;
    ultimoInput = input;
    ordenOperaciones.add('remoto');

    final error = errorAlAgregar;

    if (error != null) {
      throw error;
    }

    return RespuestaCarritoModel(
      id: 21,
      idUsuario: input.idUsuario,
      fecha: input.fecha,
      productos: [
        ProductoCarritoRespuestaModel(
          productoId: input.producto.id,
          cantidad: input.cantidad,
        ),
      ],
    );
  }
}

class FakeCarritoLocalDataSource implements CarritoLocalDataSource {
  final List<String> ordenOperaciones;

  CarritoSnapshot carritoRespuesta;

  int llamadasAgregar = 0;
  int llamadasObtener = 0;
  int llamadasLimpiar = 0;
  int llamadasObservar = 0;

  int? ultimoIdUsuario;
  Producto? ultimoProducto;
  int? ultimaCantidad;

  CarritoException? errorAlAgregar;

  FakeCarritoLocalDataSource({
    required this.ordenOperaciones,
    required this.carritoRespuesta,
  });

  @override
  Future<CarritoSnapshot> agregarOFusionarProducto(
    int idUsuario,
    Producto producto,
    int cantidad,
  ) async {
    llamadasAgregar++;
    ultimoIdUsuario = idUsuario;
    ultimoProducto = producto;
    ultimaCantidad = cantidad;
    ordenOperaciones.add('local');

    final error = errorAlAgregar;

    if (error != null) {
      throw error;
    }

    return carritoRespuesta;
  }

  @override
  Future<CarritoSnapshot> obtenerCarrito(int idUsuario) async {
    llamadasObtener++;
    ultimoIdUsuario = idUsuario;

    return carritoRespuesta;
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) async {
    llamadasLimpiar++;
    ultimoIdUsuario = idUsuario;
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    llamadasObservar++;
    ultimoIdUsuario = idUsuario;

    return const Stream<CarritoSnapshot>.empty();
  }
}
