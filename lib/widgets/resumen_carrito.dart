import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ResumenCarrito extends StatelessWidget {
  final int totalUnidades;
  final double total;

  const ResumenCarrito({
    super.key,
    required this.totalUnidades,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordeCampo),
      ),
      child: Column(
        children: [
          _FilaResumen(etiqueta: 'Artículos', valor: '$totalUnidades'),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.bordeCampo),
          const SizedBox(height: 12),
          _FilaResumen(
            etiqueta: 'Total',
            valor: '\$${total.toStringAsFixed(2)} USD',
            destacada: true,
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacada;

  const _FilaResumen({
    required this.etiqueta,
    required this.valor,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: destacada ? 16 : 14,
              fontWeight: destacada ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: destacada ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: destacada ? AppColors.primario : AppColors.textoPrincipal,
          ),
        ),
      ],
    );
  }
}
