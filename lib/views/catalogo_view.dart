import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../viewmodels/catalogo_viewmodel.dart';

class CatalogoView extends StatefulWidget {
  final CatalogoViewModel viewModel;

  const CatalogoView({super.key, required this.viewModel});

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  @override
  void initState() {
    super.initState();

    widget.viewModel.addListener(_actualizarPantalla);

    widget.viewModel.cargarProductos();
    widget.viewModel.cargarCategorias();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_actualizarPantalla);
    super.dispose();
  }

  void _actualizarPantalla() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de productos')),
      body: _construirContenido(viewModel),
    );
  }

  Widget _construirContenido(CatalogoViewModel viewModel) {
    if (viewModel.estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.mensajeError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.mensajeError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.cargarProductos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _construirFiltro(viewModel),
        Expanded(child: _construirListaProductos(viewModel)),
      ],
    );
  }

  Widget _construirFiltro(CatalogoViewModel viewModel) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          ChoiceChip(
            label: const Text('Ver todos'),
            selected: viewModel.categoriaSeleccionada == null,
            onSelected: (seleccionado) {
              if (seleccionado) {
                viewModel.mostrarTodos();
              }
            },
          ),
          const SizedBox(width: 8),
          ...viewModel.categorias.map((categoria) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(categoria),
                selected: viewModel.categoriaSeleccionada == categoria,
                onSelected: (seleccionado) {
                  if (seleccionado) {
                    viewModel.filtrarPorCategoria(categoria);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _construirListaProductos(CatalogoViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.productos.length,
      itemBuilder: (context, index) {
        final Producto producto = viewModel.productos[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.network(producto.image, fit: BoxFit.contain),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${producto.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
