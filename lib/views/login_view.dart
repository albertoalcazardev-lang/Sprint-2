import 'package:flutter/material.dart';

import '../core/di/dependency_injection.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  final VoidCallback? onLoginExitoso;
  final String? mensajeInformativo;

  const LoginView({super.key, this.onLoginExitoso, this.mensajeInformativo});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel _viewModel;

  final TextEditingController _usuarioController = TextEditingController();

  final TextEditingController _contrasenaController = TextEditingController();

  bool _mostrarContrasena = false;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<LoginViewModel>();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    final exitoso = await _viewModel.iniciarSesion(
      usuario: _usuarioController.text,
      contrasena: _contrasenaController.text,
    );

    if (!mounted || !exitoso) {
      return;
    }

    widget.onLoginExitoso?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: Center(
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
                child: AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _construirLogo(),
                        const SizedBox(height: 26),
                        const Text(
                          'Todo empieza por aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inicia sesión en Mercado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF71809B),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _construirBolsa(),
                        const SizedBox(height: 22),
                        if (widget.mensajeInformativo != null) ...[
                          _construirMensajeInformativo(
                            widget.mensajeInformativo!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_viewModel.mensajeError != null) ...[
                          _construirMensajeError(_viewModel.mensajeError!),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Usuario',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _usuarioController,
                          enabled: !_viewModel.cargando,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (_) {
                            if (_viewModel.mensajeError != null) {
                              _viewModel.limpiarError();
                            }
                          },
                          decoration: _decoracionCampo('Ingresa tu usuario'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF17233C),
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _contrasenaController,
                          enabled: !_viewModel.cargando,
                          obscureText: !_mostrarContrasena,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          onSubmitted: (_) {
                            if (!_viewModel.cargando) {
                              _iniciarSesion();
                            }
                          },
                          onChanged: (_) {
                            if (_viewModel.mensajeError != null) {
                              _viewModel.limpiarError();
                            }
                          },
                          decoration: _decoracionCampo('Ingresa tu contraseña')
                              .copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarContrasena = !_mostrarContrasena;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarContrasena
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: const Color(0xFF71809B),
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _viewModel.cargando
                                ? null
                                : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677F2),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF9FC7F8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _viewModel.cargando
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Iniciando sesión...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirLogo() {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1677F2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'm',
            style: TextStyle(
              fontSize: 35,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'mercado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF17233C),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _construirBolsa() {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1677F2),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_bag_rounded,
          size: 72,
          color: Color(0xFF1677F2),
        ),
      ),
    );
  }

  Widget _construirMensajeInformativo(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F7EA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF208A55),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Color(0xFF208A55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMensajeError(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8EA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        mensaje,
        style: const TextStyle(
          color: Color(0xFFD64555),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _decoracionCampo(String texto) {
    return InputDecoration(
      hintText: texto,
      hintStyle: const TextStyle(color: Color(0xFF9AA8BC), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF7FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFC8D9ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1677F2), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD8E3EF)),
      ),
    );
  }
}
