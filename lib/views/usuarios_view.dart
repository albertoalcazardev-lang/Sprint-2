import 'package:flutter/material.dart';

import '../core/di/dependency_injection.dart';
import '../models/usuario.dart';
import '../viewmodels/usuarios_viewmodel.dart';

class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key});

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  late final UsuariosViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = getIt<UsuariosViewModel>();

    _viewModel.cargarUsuarios();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text(
          'Usuarios registrados',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17233C),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.cargando && !_viewModel.tieneUsuarios) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_viewModel.mensajeError != null &&
              !_viewModel.tieneUsuarios) {
            return _construirError();
          }

          if (!_viewModel.tieneUsuarios) {
            return const Center(
              child: Text(
                'No hay usuarios registrados.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF71809B),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.recargarUsuarios,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.usuarios.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final usuario = _viewModel.usuarios[index];

                return _UsuarioCard(
                  usuario: usuario,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFD64555),
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.mensajeError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF17233C),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _viewModel.cargarUsuarios,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final Usuario usuario;

  const _UsuarioCard({
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEAF4FF),
            child: Text(
              usuario.nombreCompleto.isNotEmpty
                  ? usuario.nombreCompleto[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF1677F2),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17233C),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '@${usuario.usuario}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1677F2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _DatoUsuario(
                  icono: Icons.email_outlined,
                  texto: usuario.correo,
                ),
                const SizedBox(height: 6),
                _DatoUsuario(
                  icono: Icons.phone_outlined,
                  texto: usuario.telefono,
                ),
                const SizedBox(height: 6),
                _DatoUsuario(
                  icono: Icons.badge_outlined,
                  texto: 'ID: ${usuario.id}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoUsuario extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _DatoUsuario({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          size: 17,
          color: const Color(0xFF71809B),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF71809B),
            ),
          ),
        ),
      ],
    );
  }
}