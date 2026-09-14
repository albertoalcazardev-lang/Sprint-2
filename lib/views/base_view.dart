import 'package:flutter/material.dart';

import '../core/di/dependency_injection.dart';
import '../models/sesion_usuario.dart';
import '../repositories/auth_repository.dart';

class BaseView extends StatefulWidget {
  const BaseView({super.key});

  @override
  State<BaseView> createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView> {
  SesionUsuario? _sesion;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerSesion();
  }

  Future<void> _obtenerSesion() async {
    final sesion = await getIt<AuthRepository>().obtenerSesion();

    if (!mounted) {
      return;
    }

    setState(() {
      _sesion = sesion;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: _sesion == null
            ? const Text('No existe una sesión activa')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sesión iniciada correctamente',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ID de usuario: ${_sesion!.idUsuario}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rol: ${_sesion!.rol.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}
