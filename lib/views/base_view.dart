import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/di/dependency_injection.dart';
import '../models/rol_usuario.dart';
import '../models/sesion_usuario.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/catalogo_viewmodel.dart';
import 'catalogo_view.dart';

class BaseView extends StatefulWidget {
  final String? mensajeAccesoDenegado;
  final String? mensajeInformativo;

  const BaseView({
    super.key,
    this.mensajeAccesoDenegado,
    this.mensajeInformativo,
  });

  @override
  State<BaseView> createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView> {
  SesionUsuario? _sesion;
  CatalogoViewModel? _catalogoViewModel;
  bool _cargando = true;
  String? _mensajeAccesoDenegado;
  String? _mensajeInformativo;
  Timer? _temporizadorAviso;

  @override
  void initState() {
    super.initState();

    _configurarAviso(widget.mensajeAccesoDenegado);
    _mensajeInformativo = widget.mensajeInformativo;
    _obtenerSesion();
  }

  @override
  void didUpdateWidget(covariant BaseView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mensajeAccesoDenegado != widget.mensajeAccesoDenegado) {
      _configurarAviso(widget.mensajeAccesoDenegado);
    }

    if (oldWidget.mensajeInformativo != widget.mensajeInformativo) {
      _configurarAvisoInformativo(widget.mensajeInformativo);
    }
  }

  @override
  void dispose() {
    _temporizadorAviso?.cancel();
    _catalogoViewModel?.dispose();
    super.dispose();
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

  void _configurarAviso(String? mensaje) {
    _temporizadorAviso?.cancel();
    _mensajeAccesoDenegado = mensaje;

    if (mensaje == null || mensaje.isEmpty) {
      return;
    }

    _temporizadorAviso = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeAccesoDenegado = null;
      });
    });
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
    if (_cargando) {
      return const Scaffold(
        backgroundColor: AppColors.fondoGeneral,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primario),
        ),
      );
    }

    if (_sesion == null) {
      return const Scaffold(
        backgroundColor: AppColors.fondoGeneral,
        body: Center(
          child: Text(
            'No existe una sesión activa',
            style: TextStyle(color: AppColors.textoPrincipal),
          ),
        ),
      );
    }

    final esAdministrador = _sesion!.rol == RolUsuario.administrador;
    final esCliente = _sesion!.rol == RolUsuario.cliente;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _construirEncabezado(),
                  const SizedBox(height: 24),
                  if (_mensajeAccesoDenegado != null) ...[
                    _construirAvisoAccesoDenegado(_mensajeAccesoDenegado!),
                    const SizedBox(height: 18),
                  ],
                  if (_mensajeInformativo != null) ...[
                    _construirAvisoInformativo(_mensajeInformativo!),
                    const SizedBox(height: 18),
                  ],
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Productos',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                      if (esAdministrador) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.go('/products/new');
                            },
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Nuevo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primario,
                              foregroundColor: AppColors.blanco,
                              elevation: 2,
                              shadowColor: const Color(0x441262F3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explora los artículos disponibles en el catálogo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _construirContenidoCatalogoPendiente(),
                  const SizedBox(height: 22),
                  if (esAdministrador) ...[
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go('/usuarios');
                        },
                        icon: const Icon(Icons.people_alt_rounded),
                        label: const Text('Usuarios registrados'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textoPrincipal,
                          backgroundColor: AppColors.blanco,
                          side: const BorderSide(color: AppColors.bordeCampo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go('/carritos');
                        },
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Histórico de carritos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textoPrincipal,
                          backgroundColor: AppColors.blanco,
                          side: const BorderSide(color: AppColors.bordeCampo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (esCliente) ...[
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/cart');
                        },
                        icon: const Icon(Icons.shopping_cart_rounded),
                        label: const Text('Mi carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primario,
                          foregroundColor: AppColors.blanco,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/cuenta');
                      },
                      icon: const Icon(Icons.person_rounded),
                      label: const Text('Mi cuenta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primario,
                        backgroundColor: AppColors.blanco,
                        side: const BorderSide(color: AppColors.bordeCampo),
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
      ),
    );
  }

  Widget _construirEncabezado() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primario,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Text(
            'm',
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.blanco,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'mercado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textoPrincipal,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEBFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _nombreRol(_sesion!.rol),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primario,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirAvisoAccesoDenegado(String mensaje) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: mensaje,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: AppColors.error, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAvisoInformativo(String mensaje) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: mensaje,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoExito,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.exito,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.exito,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenidoCatalogoPendiente() {
    // Algunos tests de rutas registran solo las dependencias de autenticación.
    // En producción el ViewModel está registrado y se conserva durante toda la
    // vida de BaseView para no repetir consultas al reconstruir la pantalla.
    if (!getIt.isRegistered<CatalogoViewModel>()) {
      return _construirCatalogoNoDisponible();
    }

    _catalogoViewModel ??= getIt<CatalogoViewModel>();
    return CatalogoView(viewModel: _catalogoViewModel!);
  }

  Widget _construirCatalogoNoDisponible() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141262F3),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 58, color: AppColors.primario),
          SizedBox(height: 16),
          Text(
            'Catálogo de productos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No fue posible inicializar el catálogo en este contexto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  void _configurarAvisoInformativo(String? mensaje) {
    _temporizadorAviso?.cancel();
    _mensajeInformativo = mensaje;

    if (mensaje == null || mensaje.isEmpty) {
      return;
    }

    _temporizadorAviso = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _mensajeInformativo = null;
      });
    });
  }
}
