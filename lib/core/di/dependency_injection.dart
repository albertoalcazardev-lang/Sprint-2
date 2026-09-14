import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/auth_repository_impl.dart';
import '../../services/auth_service.dart';
import '../../services/auth_service_impl.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../network/api_client.dart';
import '../network/conectividad_service.dart';
import '../storage/secure_storage.dart';
import '../utils/mapeador_rol.dart';

final getIt = GetIt.instance;

void configurarDependencias() {
  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  }

  if (!getIt.isRegistered<Connectivity>()) {
    getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  }

  if (!getIt.isRegistered<ConectividadService>()) {
    getIt.registerLazySingleton<ConectividadService>(
      () => ConectividadServiceImpl(getIt<Connectivity>()),
    );
  }

  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  if (!getIt.isRegistered<SecureStorage>()) {
    getIt.registerLazySingleton<SecureStorage>(
      () => SecureStorageImpl(getIt<FlutterSecureStorage>()),
    );
  }

  if (!getIt.isRegistered<MapeadorRol>()) {
    getIt.registerLazySingleton<MapeadorRol>(() => MapeadorRol());
  }

  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerLazySingleton<AuthService>(
      () => AuthServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<AuthService>(),
        getIt<SecureStorage>(),
        getIt<MapeadorRol>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginViewModel>()) {
    getIt.registerFactory<LoginViewModel>(
      () =>
          LoginViewModel(getIt<AuthRepository>(), getIt<ConectividadService>()),
    );
  }
}
