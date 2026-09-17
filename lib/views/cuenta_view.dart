import 'package:flutter/material.dart';

import '../core/di/dependency_injection.dart';
import '../models/rol_usuario.dart';
import '../viewmodels/cuenta_viewmodel.dart';

class CuentaView extends StatefulWidget {
  final VoidCallback onSesionCerrada;

  const CuentaView({super.key, required this.onSesionCerrada});

  @override
  State<CuentaView> createState() => _CuentaViewState();
}

class _CuentaViewState extends State<CuentaView> {
  late final CuentaViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = getIt<CuentaViewModel>();
    _viewModel.cargarSesion();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final cerrado = await _viewModel.cerrarSesion();

    if (!mounted || !cerrado) {
      return;
    }

    widget.onSesionCerrada();
  }

  String _nombreRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return 'Administrador';
      case RolUsuario.auditor:
        return 'Auditor';
      case RolUsuario.cliente:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            if (_viewModel.cargando && _viewModel.sesion == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final sesion = _viewModel.sesion;

            if (sesion == null) {
              return const Center(child: Text('No existe una sesión activa'));
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1677F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'm',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'mercado',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF17233C),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _nombreRol(sesion.rol),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1677F2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'Mi cuenta',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1677F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Usuario #${sesion.idUsuario}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _nombreRol(sesion.rol),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF71809B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF20A464),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sesión activa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF17233C),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Al salir se eliminará la información local de tu sesión.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Color(0xFF71809B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.cargando
                                ? null
                                : _cerrarSesion,
                            icon: _viewModel.cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.logout_rounded),
                            label: Text(
                              _viewModel.cargando
                                  ? 'Cerrando sesión...'
                                  : 'Cerrar sesión',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD64555),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE9A1A9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
