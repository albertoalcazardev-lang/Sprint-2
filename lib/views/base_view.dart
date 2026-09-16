import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/dependency_injection.dart';
import '../models/sesion_usuario.dart';
import '../repositories/auth_repository.dart';
import 'catalogo_view.dart';

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

  String _nombreRol() {
    final rol = _sesion?.rol;

    if (rol == null) {
      return '';
    }

    switch (rol.name) {
      case 'administrador':
        return 'Administrador';
      case 'auditor':
        return 'Auditor';
      case 'cliente':
        return 'Cliente';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sesion == null) {
      return const Scaffold(
        body: Center(child: Text('No existe una sesión activa')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text('Catálogo de productos'),
        backgroundColor: const Color(0xFF1677F2),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 55,
                    color: Color(0xFF1677F2),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sesión iniciada correctamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17233C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ID de usuario: ${_sesion!.idUsuario}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF17233C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rol: ${_nombreRol()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1677F2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/cuenta');
                      },
                      icon: const Icon(Icons.person_rounded),
                      label: const Text('Mi cuenta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677F2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Catálogo general',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17233C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: CatalogoView(viewModel: getIt())),
          ],
        ),
      ),
    );
  }
}
