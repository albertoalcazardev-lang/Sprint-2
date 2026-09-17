import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/di/dependency_injection.dart';
import '../core/validators/producto_validadores.dart';
import '../viewmodels/crear_producto_viewmodel.dart';
import '../widgets/campo_producto.dart';

/// US06/E1 y E2 — P17, P18 y P19: formulario de creación.
class CrearProductoView extends StatefulWidget {
  final VoidCallback onVolver;
  final VoidCallback onAccesoNoAutorizado;

  const CrearProductoView({
    super.key,
    required this.onVolver,
    required this.onAccesoNoAutorizado,
  });

  @override
  State<CrearProductoView> createState() => _CrearProductoViewState();
}

class _CrearProductoViewState extends State<CrearProductoView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  final FocusNode _tituloFocus = FocusNode();
  final FocusNode _precioFocus = FocusNode();
  final FocusNode _categoriaFocus = FocusNode();
  final FocusNode _imageUrlFocus = FocusNode();
  final FocusNode _descripcionFocus = FocusNode();

  final List<TextInputFormatter> _precioFormatters = [
    TextInputFormatter.withFunction((valorAnterior, valorNuevo) {
      final formatoValido = RegExp(r'^\d*(?:[.,]\d*)?$')
          .hasMatch(valorNuevo.text);

      return formatoValido ? valorNuevo : valorAnterior;
    }),
  ];

  late final CrearProductoViewModel _viewModel;

  String? _categoriaSeleccionada;
  bool _validacionActivada = false;

  @override
  void initState() {
    super.initState();

    _viewModel = getIt<CrearProductoViewModel>();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _viewModel.inicializar();

    if (!mounted) {
      return;
    }

    if (_viewModel.accesoNoAutorizado) {
      widget.onAccesoNoAutorizado();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tituloController.dispose();
    _precioController.dispose();
    _imageUrlController.dispose();
    _descripcionController.dispose();

    _tituloFocus.dispose();
    _precioFocus.dispose();
    _categoriaFocus.dispose();
    _imageUrlFocus.dispose();
    _descripcionFocus.dispose();

    _viewModel.dispose();

    super.dispose();
  }

  Future<void> _guardarProducto() async {
    if (_viewModel.enviandoProducto) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _validacionActivada = true;
    });

    final formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      _enfocarPrimerCampoInvalido();
      return;
    }

    final creado = await _viewModel.crearProducto(
      titulo: _tituloController.text,
      precio: _precioController.text,
      categoria: _categoriaSeleccionada,
      imageUrl: _imageUrlController.text,
      descripcion: _descripcionController.text,
    );

    if (!mounted) {
      return;
    }

    if (_viewModel.accesoNoAutorizado) {
      widget.onAccesoNoAutorizado();
      return;
    }

    if (!creado) {
      return;
    }

    final mensajeConfirmacion =
        _viewModel.mensajeExito ?? 'Producto creado (Simulación).';

    _tituloController.clear();
    _precioController.clear();
    _imageUrlController.clear();
    _descripcionController.clear();

    setState(() {
      _categoriaSeleccionada = null;
      _validacionActivada = false;
    });

    _formKey.currentState?.reset();

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.exito,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.blanco),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensajeConfirmacion,
                  style: const TextStyle(
                    color: AppColors.blanco,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _enfocarPrimerCampoInvalido() {
    if (ProductoValidadores.validarTitulo(_tituloController.text) != null) {
      _tituloFocus.requestFocus();
      return;
    }

    if (ProductoValidadores.validarPrecio(_precioController.text) != null) {
      _precioFocus.requestFocus();
      return;
    }

    if (ProductoValidadores.validarCategoria(_categoriaSeleccionada) != null) {
      _categoriaFocus.requestFocus();
      return;
    }

    if (ProductoValidadores.validarImageUrl(_imageUrlController.text) != null) {
      _imageUrlFocus.requestFocus();
      return;
    }

    if (ProductoValidadores.validarDescripcion(_descripcionController.text) !=
        null) {
      _descripcionFocus.requestFocus();
    }
  }

  void _registrarEdicion(String _) {
    _viewModel.registrarEdicion();
  }

  void _seleccionarCategoria(String? categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });

    _viewModel.registrarEdicion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            if (_viewModel.accesoNoAutorizado) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _construirEncabezado(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_viewModel.mensajeExito != null) ...[
                              _construirAvisoExito(_viewModel.mensajeExito!),
                              const SizedBox(height: 16),
                            ],
                            if (_viewModel.mensajeError != null) ...[
                              _construirAvisoError(_viewModel.mensajeError!),
                              const SizedBox(height: 16),
                            ],
                            _construirFormulario(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _viewModel.enviandoProducto ? null : widget.onVolver,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Volver'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textoSecundario,
              minimumSize: const Size(48, 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Nuevo producto',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Rol Administrador',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMINISTRADOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primario,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    final formularioDeshabilitado = _viewModel.enviandoProducto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Form(
        key: _formKey,
        autovalidateMode: _validacionActivada
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoProducto(
              etiqueta: 'Título',
              placeholder: 'Ej. Mochila urbana',
              controller: _tituloController,
              focusNode: _tituloFocus,
              validator: ProductoValidadores.validarTitulo,
              enabled: !formularioDeshabilitado,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: _registrarEdicion,
              onFieldSubmitted: (_) {
                _precioFocus.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            CampoProducto(
              etiqueta: 'Precio (USD)',
              placeholder: '0.00',
              controller: _precioController,
              focusNode: _precioFocus,
              validator: ProductoValidadores.validarPrecio,
              enabled: !formularioDeshabilitado,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: _precioFormatters,
              onChanged: _registrarEdicion,
              onFieldSubmitted: (_) {
                _categoriaFocus.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            _construirSelectorCategoria(formularioDeshabilitado),
            const SizedBox(height: 16),
            CampoProducto(
              etiqueta: 'URL de imagen',
              placeholder: 'https://ejemplo.com/imagen.jpg',
              controller: _imageUrlController,
              focusNode: _imageUrlFocus,
              validator: ProductoValidadores.validarImageUrl,
              enabled: !formularioDeshabilitado,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: _registrarEdicion,
              onFieldSubmitted: (_) {
                _descripcionFocus.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            CampoProducto(
              etiqueta: 'Descripción',
              placeholder: 'Describe el producto',
              controller: _descripcionController,
              focusNode: _descripcionFocus,
              validator: ProductoValidadores.validarDescripcion,
              enabled: !formularioDeshabilitado,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              onChanged: _registrarEdicion,
              onFieldSubmitted: (_) {
                if (_viewModel.puedeGuardar) {
                  _guardarProducto();
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _viewModel.puedeGuardar ? _guardarProducto : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primario,
                  foregroundColor: AppColors.blanco,
                  disabledBackgroundColor: AppColors.primarioDeshabilitado,
                  disabledForegroundColor: AppColors.blanco,
                  elevation: 3,
                  shadowColor: const Color(0x551262F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _viewModel.enviandoProducto
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.blanco,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Guardando producto...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Guardar producto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _viewModel.enviandoProducto ? null : widget.onVolver,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textoSecundario,
                  backgroundColor: AppColors.superficie,
                  side: const BorderSide(color: AppColors.bordeCampo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSelectorCategoria(bool formularioDeshabilitado) {
    final cargando = _viewModel.cargandoCategorias;
    final tieneCategorias = _viewModel.categorias.isNotEmpty;

    return Semantics(
      label: 'Categoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categoría',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _categoriaSeleccionada,
            focusNode: _categoriaFocus,
            isExpanded: true,
            validator: ProductoValidadores.validarCategoria,
            icon: cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primario,
                    ),
                  )
                : const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textoSecundario,
                  ),
            hint: Text(
              cargando ? 'Cargando categorías...' : 'Selecciona una categoría',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textoSugerencia,
              ),
            ),
            items: _viewModel.categorias.map((categoria) {
              return DropdownMenuItem<String>(
                value: categoria,
                child: Text(
                  categoria,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textoPrincipal,
                  ),
                ),
              );
            }).toList(),
            onChanged: formularioDeshabilitado || cargando || !tieneCategorias
                ? null
                : _seleccionarCategoria,
            decoration: InputDecoration(
              filled: true,
              fillColor: formularioDeshabilitado
                  ? AppColors.fondoGeneral
                  : AppColors.fondoCampo,
              constraints: const BoxConstraints(minHeight: 48),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: AppColors.error,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.bordeCampo),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.primario,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.4,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.7,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.bordeCampo),
              ),
            ),
          ),
          if (_viewModel.mensajeErrorCategorias != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fondoError,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No pudimos cargar las categorías.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: cargando ? null : _viewModel.cargarCategorias,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirAvisoExito(String mensaje) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 21,
              color: AppColors.exito,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.exito,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAvisoError(String mensaje) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 21,
              color: AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
