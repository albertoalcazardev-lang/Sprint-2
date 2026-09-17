import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// US09/E1 — Selector entero con mínimo de una unidad.
class SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final bool habilitado;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;

  const SelectorCantidad({
    super.key,
    required this.cantidad,
    required this.onIncrementar,
    required this.onDisminuir,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controles = _construirControles();

        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirEtiqueta(),
              const SizedBox(height: 10),
              controles,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _construirEtiqueta()),
            const SizedBox(width: 16),
            controles,
          ],
        );
      },
    );
  }

  Widget _construirEtiqueta() {
    return const Text(
      'Cantidad',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
    );
  }

  Widget _construirControles() {
    final puedeDisminuir = habilitado && cantidad > 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondoCampo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordeCampo),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: puedeDisminuir ? onDisminuir : null,
              tooltip: 'Disminuir cantidad',
              icon: const Icon(Icons.remove_rounded, size: 22),
              color: AppColors.primario,
              disabledColor: AppColors.textoSugerencia,
            ),
          ),
          Container(
            width: 58,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.blanco,
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.bordeCampo),
              ),
            ),
            child: Semantics(
              label: 'Cantidad seleccionada',
              value: cantidad.toString(),
              liveRegion: true,
              child: ExcludeSemantics(
                child: Text(
                  cantidad.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textoPrincipal,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: habilitado ? onIncrementar : null,
              tooltip: 'Aumentar cantidad',
              icon: const Icon(Icons.add_rounded, size: 22),
              color: AppColors.primario,
              disabledColor: AppColors.textoSugerencia,
            ),
          ),
        ],
      ),
    );
  }
}
