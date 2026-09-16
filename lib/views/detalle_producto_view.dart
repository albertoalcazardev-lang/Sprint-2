import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../models/rol_usuario.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/detalle_producto_viewmodel.dart';

class DetalleProductoView extends StatefulWidget {
  final DetalleProductoViewModel viewModel;
  final AuthRepository authRepository;
  final int productoId;

  const DetalleProductoView({
    super.key,
    required this.viewModel,
    required this.authRepository,
    required this.productoId,
  });

  @override
  State<DetalleProductoView> createState() => _DetalleProductoViewState();
}

class _DetalleProductoViewState extends State<DetalleProductoView> {
  bool esAdministrador = false;

  @override
  void initState() {
    super.initState();

    widget.viewModel.addListener(_actualizarPantalla);

    _cargarRol();
    widget.viewModel.cargarProducto(widget.productoId);
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

  Future<void> _cargarRol() async {
    final sesion = await widget.authRepository.obtenerSesion();

    if (!mounted) {
      return;
    }

    setState(() {
      esAdministrador = sesion?.rol == RolUsuario.administrador;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: _construirContenido(viewModel),
    );
  }

  Widget _construirContenido(DetalleProductoViewModel viewModel) {
    if (viewModel.estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.mensajeError != null && viewModel.producto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
      });

      return const Center(child: CircularProgressIndicator());
    }

    final producto = viewModel.producto;

    if (producto == null) {
      return const Center(child: Text('Producto no disponible'));
    }

    return _construirDetalle(producto);
  }

  Widget _construirDetalle(Producto producto) {
    final viewModel = widget.viewModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.network(producto.image, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            producto.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Text(
            '\$${producto.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          const Text(
            'Categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(producto.category, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 20),

          const Text(
            'Descripción',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            producto.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),

          if (esAdministrador) ...[
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: viewModel.estaGuardando
                        ? null
                        : () => _mostrarFormularioEdicion(producto),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: viewModel.estaGuardando
                        ? null
                        : () => _mostrarConfirmacionEliminar(producto),
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),

            if (viewModel.estaGuardando) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _mostrarFormularioEdicion(Producto producto) async {
    final tituloController = TextEditingController(text: producto.title);

    final precioController = TextEditingController(
      text: producto.price.toString(),
    );

    final descripcionController = TextEditingController(
      text: producto.description,
    );

    final categoriaController = TextEditingController(text: producto.category);

    final imagenController = TextEditingController(text: producto.image);

    final formularioValido = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Precio'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: imagenController,
                  decoration: const InputDecoration(labelText: 'URL de imagen'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (formularioValido != true || !mounted) {
      tituloController.dispose();
      precioController.dispose();
      descripcionController.dispose();
      categoriaController.dispose();
      imagenController.dispose();
      return;
    }

    final precio = double.tryParse(precioController.text.trim());

    if (precio == null || precio < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El precio no es válido.')));

      tituloController.dispose();
      precioController.dispose();
      descripcionController.dispose();
      categoriaController.dispose();
      imagenController.dispose();
      return;
    }

    final productoActualizado = Producto(
      id: producto.id,
      title: tituloController.text.trim(),
      price: precio,
      description: descripcionController.text.trim(),
      category: categoriaController.text.trim(),
      image: imagenController.text.trim(),
    );

    final actualizado = await widget.viewModel.actualizarProducto(
      productoActualizado,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actualizado
              ? 'Producto actualizado correctamente.'
              : 'No se pudo actualizar el producto.',
        ),
      ),
    );

    tituloController.dispose();
    precioController.dispose();
    descripcionController.dispose();
    categoriaController.dispose();
    imagenController.dispose();
  }

  Future<void> _mostrarConfirmacionEliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text('¿Deseas eliminar "${producto.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La eliminación se implementará en el siguiente paso.'),
      ),
    );
  }
}
