import '../core/errors/carrito_exception.dart';
import '../data_sources/carrito_local_data_source.dart';
import '../data_sources/carrito_mutable_local_data_source.dart';
import '../models/agregar_carrito_input.dart';
import '../models/carrito_snapshot.dart';
import '../services/carrito_service.dart';
import 'carrito_repository.dart';

class CarritoRepositoryImpl implements CarritoRepository {
  final CarritoService carritoService;
  final CarritoLocalDataSource carritoLocalDataSource;

  CarritoRepositoryImpl(this.carritoService, this.carritoLocalDataSource);

  /// US09/E1-E2 — Confirma remotamente y después fusiona localmente.
  @override
  Future<CarritoSnapshot> agregarProducto(AgregarCarritoInput input) async {
    try {
      _validarInput(input);

      // El orden es importante: no modificar el estado local antes del POST.
      final respuesta = await carritoService.agregarProducto(input);

      final fuenteLocal = carritoLocalDataSource;

      if (fuenteLocal is CarritoMutableLocalDataSource) {
        final fuenteMutable = fuenteLocal as CarritoMutableLocalDataSource;

        return await fuenteMutable.agregarOFusionarProductoConIdRemoto(
          input.idUsuario,
          input.producto,
          input.cantidad,
          respuesta.id,
        );
      }

      return await carritoLocalDataSource.agregarOFusionarProducto(
        input.idUsuario,
        input.producto,
        input.cantidad,
      );
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const CarritoException(
        'No pudimos agregar el producto. '
        'Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<CarritoSnapshot> obtenerCarritoActual(int idUsuario) async {
    try {
      _validarIdUsuario(idUsuario);

      return await carritoLocalDataSource.obtenerCarrito(idUsuario);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException(
        'No pudimos recuperar el carrito local.',
      );
    }
  }

  @override
  Future<void> limpiarCarrito(int idUsuario) async {
    try {
      _validarIdUsuario(idUsuario);

      await carritoLocalDataSource.limpiarCarrito(idUsuario);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException(
        'No pudimos limpiar el carrito local.',
      );
    }
  }

  @override
  Stream<CarritoSnapshot> observarCarrito(int idUsuario) {
    _validarIdUsuario(idUsuario);

    return carritoLocalDataSource.observarCarrito(idUsuario);
  }

  void _validarInput(AgregarCarritoInput input) {
    _validarIdUsuario(input.idUsuario);

    if (input.producto.id <= 0) {
      throw const DatosCarritoInvalidosException('No se encontró el producto.');
    }

    if (input.cantidad <= 0) {
      throw const DatosCarritoInvalidosException(
        'La cantidad debe ser mayor que cero.',
      );
    }
  }

  void _validarIdUsuario(int idUsuario) {
    if (idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }
  }
}
