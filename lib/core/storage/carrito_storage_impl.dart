import 'package:shared_preferences/shared_preferences.dart';

import '../errors/carrito_exception.dart';
import 'carrito_storage.dart';

class CarritoStorageImpl implements CarritoStorage {
  static const String _prefijoClave = 'mercado_carrito_usuario_';

  final SharedPreferencesAsync sharedPreferences;

  CarritoStorageImpl(this.sharedPreferences);

  @override
  Future<String?> obtenerCarrito(int idUsuario) async {
    try {
      final clave = _construirClave(idUsuario);

      return await sharedPreferences.getString(clave);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException(
        'No pudimos recuperar el carrito local.',
      );
    }
  }

  @override
  Future<void> guardarCarrito(int idUsuario, String carritoJson) async {
    try {
      final clave = _construirClave(idUsuario);

      if (carritoJson.trim().isEmpty) {
        throw const DatosCarritoInvalidosException(
          'El carrito local no contiene información válida.',
        );
      }

      await sharedPreferences.setString(clave, carritoJson);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException();
    }
  }

  @override
  Future<void> eliminarCarrito(int idUsuario) async {
    try {
      final clave = _construirClave(idUsuario);

      await sharedPreferences.remove(clave);
    } on CarritoException {
      rethrow;
    } catch (_) {
      throw const PersistenciaCarritoException(
        'No pudimos limpiar el carrito local.',
      );
    }
  }

  String _construirClave(int idUsuario) {
    if (idUsuario <= 0) {
      throw const DatosCarritoInvalidosException(
        'No se pudo identificar al usuario del carrito.',
      );
    }

    return '$_prefijoClave$idUsuario';
  }
}
