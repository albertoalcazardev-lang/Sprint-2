import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/item_carrito.dart';

class TarjetaItemCarrito extends StatelessWidget {
  final ItemCarrito item;
  final bool procesando;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;
  final VoidCallback onEliminar;

  const TarjetaItemCarrito({
    super.key,
    required this.item,
    required this.procesando,
    required this.onIncrementar,
    required this.onDisminuir,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${item.producto.titulo}, cantidad ${item.cantidad}, '
          'subtotal ${item.subtotal.toStringAsFixed(2)} dólares',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x121262F3),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagenProducto(url: item.producto.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.producto.categoria,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${item.producto.precio.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _BotonCantidad(
                        clave: ValueKey('disminuir-${item.producto.id}'),
                        icono: item.cantidad == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded,
                        etiqueta: item.cantidad == 1
                            ? 'Eliminar producto'
                            : 'Disminuir cantidad',
                        onPressed: procesando ? null : onDisminuir,
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${item.cantidad}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                      _BotonCantidad(
                        clave: ValueKey('incrementar-${item.producto.id}'),
                        icono: Icons.add_rounded,
                        etiqueta: 'Aumentar cantidad',
                        onPressed: procesando ? null : onIncrementar,
                      ),
                      IconButton(
                        key: ValueKey('eliminar-${item.producto.id}'),
                        tooltip: 'Eliminar producto',
                        onPressed: procesando ? null : onEliminar,
                        color: AppColors.error,
                        icon: procesando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primario,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subtotal: \$${item.subtotal.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagenProducto extends StatelessWidget {
  final String url;

  const _ImagenProducto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordeCampo),
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textoSecundario,
            size: 34,
          );
        },
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final Key clave;
  final IconData icono;
  final String etiqueta;
  final VoidCallback? onPressed;

  const _BotonCantidad({
    required this.clave,
    required this.icono,
    required this.etiqueta,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: clave,
      tooltip: etiqueta,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primario,
        backgroundColor: AppColors.fondoCampo,
        disabledForegroundColor: AppColors.textoSugerencia,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.bordeCampo),
        ),
      ),
      icon: Icon(icono, size: 21),
    );
  }
}
