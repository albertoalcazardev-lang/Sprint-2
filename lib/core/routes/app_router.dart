import 'package:go_router/go_router.dart';

import '../../views/base_view.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const BaseView();
        },
      ),
    ],
  );
}
