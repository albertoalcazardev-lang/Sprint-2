import 'package:flutter/material.dart';

import 'core/di/dependency_injection.dart';
import 'core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  configurarDependencias();

  runApp(const TiendaApp());
}

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Tienda',
      routerConfig: AppRouter.router,
    );
  }
}
