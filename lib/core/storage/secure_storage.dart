import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<void> guardar(String clave, String valor);

  Future<String?> obtener(String clave);

  Future<void> eliminar(String clave);

  Future<void> limpiar();
}

class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorageImpl(this._storage);

  @override
  Future<void> guardar(String clave, String valor) {
    return _storage.write(key: clave, value: valor);
  }

  @override
  Future<String?> obtener(String clave) {
    return _storage.read(key: clave);
  }

  @override
  Future<void> eliminar(String clave) {
    return _storage.delete(key: clave);
  }

  @override
  Future<void> limpiar() {
    return _storage.deleteAll();
  }
}
