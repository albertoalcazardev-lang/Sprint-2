import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_flutter/core/utils/mapeador_rol.dart';
import 'package:tienda_flutter/models/rol_usuario.dart';

void main() {
  late MapeadorRol mapeadorRol;

  setUp(() {
    mapeadorRol = MapeadorRol();
  });

  test('ID 1 debe ser administrador', () {
    expect(mapeadorRol.obtenerRolPorId(1), RolUsuario.administrador);
  });

  test('ID 2 debe ser administrador', () {
    expect(mapeadorRol.obtenerRolPorId(2), RolUsuario.administrador);
  });

  test('ID 3 debe ser auditor', () {
    expect(mapeadorRol.obtenerRolPorId(3), RolUsuario.auditor);
  });

  test('IDs restantes deben ser cliente', () {
    expect(mapeadorRol.obtenerRolPorId(4), RolUsuario.cliente);

    expect(mapeadorRol.obtenerRolPorId(10), RolUsuario.cliente);
  });
}
