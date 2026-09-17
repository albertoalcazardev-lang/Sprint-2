import 'package:flutter/material.dart';

import '../core/di/dependency_injection.dart';
import '../models/carrito.dart';
import '../models/producto_carrito.dart';
import '../viewmodels/carritos_viewmodel.dart';

class CarritosView extends StatefulWidget {
  const CarritosView({super.key});

  @override
  State<CarritosView> createState() => _CarritosViewState();
}

class _CarritosViewState extends State<CarritosView> {
  late final CarritosViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<CarritosViewModel>();
    _viewModel.cargarCarritos();
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
          'Histórico global de carritos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17233C),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.cargando && !_viewModel.tieneCarritos) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.mensajeError != null && !_viewModel.tieneCarritos) {
            return _construirError();
          }

          if (!_viewModel.tieneCarritos) {
            return const Center(
              child: Text(
                'No hay carritos registrados.',
                style: TextStyle(fontSize: 16, color: Color(0xFF71809B)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _viewModel.recargarCarritos,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumenHistorico(
                  totalCarritos: _viewModel.totalCarritos,
                  totalUsuarios: _viewModel.totalUsuarios,
                ),
                const SizedBox(height: 16),
                ..._viewModel.carritos.map(
                  (carrito) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CarritoCard(carrito: carrito),
                  ),
                ),
              ],
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
              style: const TextStyle(fontSize: 16, color: Color(0xFF17233C)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _viewModel.cargarCarritos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenHistorico extends StatelessWidget {
  final int totalCarritos;
  final int totalUsuarios;

  const _ResumenHistorico({
    required this.totalCarritos,
    required this.totalUsuarios,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResumenDato(
              icono: Icons.shopping_cart_rounded,
              valor: '$totalCarritos',
              etiqueta: 'Carritos',
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: const Color(0xFFD5E4F5),
          ),
          Expanded(
            child: _ResumenDato(
              icono: Icons.people_alt_rounded,
              valor: '$totalUsuarios',
              etiqueta: 'Usuarios',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenDato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _ResumenDato({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: const Color(0xFF1677F2), size: 26),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17233C),
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 13, color: Color(0xFF71809B)),
        ),
      ],
    );
  }
}

class _CarritoCard extends StatelessWidget {
  final Carrito carrito;

  const _CarritoCard({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF4FF),
          child: Text(
            '#${carrito.id}',
            style: const TextStyle(
              color: Color(0xFF1677F2),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          'Carrito #${carrito.id}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF17233C),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Usuario #${carrito.usuarioId}  •  ${_formatearFecha(carrito.fecha)}',
            style: const TextStyle(color: Color(0xFF71809B)),
          ),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _DetalleResumen(
                  icono: Icons.inventory_2_outlined,
                  texto: '${carrito.totalProductosDiferentes} productos diferentes',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetalleResumen(
                  icono: Icons.shopping_basket_outlined,
                  texto: '${carrito.totalArticulos} artículos en total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Productos del carrito',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17233C),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...carrito.productos.map(
            (producto) => _ProductoFila(producto: producto),
          ),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }
}

class _DetalleResumen extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _DetalleResumen({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: const Color(0xFF1677F2)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12, color: Color(0xFF71809B)),
          ),
        ),
      ],
    );
  }
}

class _ProductoFila extends StatelessWidget {
  final ProductoCarrito producto;

  const _ProductoFila({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: Color(0xFF71809B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Producto #${producto.productoId}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF17233C),
              ),
            ),
          ),
          Text(
            'Cantidad: ${producto.cantidad}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1677F2),
            ),
          ),
        ],
      ),
    );
  }
}
