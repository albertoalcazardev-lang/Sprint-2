import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data_sources/carrito_local_data_source.dart';
import '../../data_sources/carrito_local_data_source_impl.dart';
import '../../data_sources/carrito_mutable_local_data_source.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/auth_repository_impl.dart';
import '../../repositories/carrito_repository.dart';
import '../../repositories/carrito_repository_impl.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/product_repository_impl.dart';
import '../../repositories/usuario_repository.dart';
import '../../repositories/usuario_repository_impl.dart';
import '../../repositories/gestion_carrito_repository.dart';
import '../../repositories/gestion_carrito_repository_impl.dart';
import '../../repositories/historico_carrito_repository.dart';
import '../../repositories/historico_carrito_repository_impl.dart';
import '../../services/auth_service.dart';
import '../../services/auth_service_impl.dart';
import '../../services/carrito_service.dart';
import '../../services/carrito_service_impl.dart';
import '../../services/gestion_carrito_service.dart';
import '../../services/historico_carrito_service.dart';
import '../../services/historico_carrito_service_impl.dart';
import '../../services/product_service.dart';
import '../../services/product_service_impl.dart';
import '../../services/usuario_service.dart';
import '../../services/usuario_service_impl.dart';
import '../../viewmodels/agregar_carrito_viewmodel.dart';
import '../../viewmodels/carrito_viewmodel.dart';
import '../../viewmodels/carritos_viewmodel.dart';
import '../../viewmodels/crear_producto_viewmodel.dart';
import '../../viewmodels/cuenta_viewmodel.dart';
import '../../viewmodels/editar_producto_viewmodel.dart';
import '../../viewmodels/eliminar_producto_viewmodel.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../viewmodels/usuarios_viewmodel.dart';
import '../network/api_client.dart';
import '../network/conectividad_service.dart';
import '../storage/carrito_storage.dart';
import '../storage/carrito_storage_impl.dart';
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

  if (!getIt.isRegistered<SharedPreferencesAsync>()) {
    getIt.registerLazySingleton<SharedPreferencesAsync>(
      () => SharedPreferencesAsync(),
    );
  }

  if (!getIt.isRegistered<CarritoStorage>()) {
    getIt.registerLazySingleton<CarritoStorage>(
      () => CarritoStorageImpl(getIt<SharedPreferencesAsync>()),
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

  if (!getIt.isRegistered<ProductService>()) {
    getIt.registerLazySingleton<ProductService>(
      () => ProductServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<ProductRepository>()) {
    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(getIt<ProductService>()),
    );
  }

  if (!getIt.isRegistered<UsuarioService>()) {
    getIt.registerLazySingleton<UsuarioService>(
      () => UsuarioServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<UsuarioRepository>()) {
    getIt.registerLazySingleton<UsuarioRepository>(
      () => UsuarioRepositoryImpl(getIt<UsuarioService>()),
    );
  }

  if (!getIt.isRegistered<CarritoService>()) {
    getIt.registerLazySingleton<CarritoService>(
      () => CarritoServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<CarritoLocalDataSource>()) {
    getIt.registerLazySingleton<CarritoLocalDataSource>(
      () => CarritoLocalDataSourceImpl(getIt<CarritoStorage>()),
    );
  }

  if (!getIt.isRegistered<CarritoMutableLocalDataSource>()) {
    getIt.registerLazySingleton<CarritoMutableLocalDataSource>(
      () => getIt<CarritoLocalDataSource>() as CarritoMutableLocalDataSource,
    );
  }

  if (!getIt.isRegistered<GestionCarritoService>()) {
    getIt.registerLazySingleton<GestionCarritoService>(
      () => CarritoServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<CarritoRepository>()) {
    getIt.registerLazySingleton<CarritoRepository>(
      () => CarritoRepositoryImpl(
        getIt<CarritoService>(),
        getIt<CarritoLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GestionCarritoRepository>()) {
    getIt.registerLazySingleton<GestionCarritoRepository>(
      () => GestionCarritoRepositoryImpl(
        getIt<GestionCarritoService>(),
        getIt<CarritoLocalDataSource>(),
        getIt<CarritoMutableLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<HistoricoCarritoService>()) {
    getIt.registerLazySingleton<HistoricoCarritoService>(
      () => HistoricoCarritoServiceImpl(getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<HistoricoCarritoRepository>()) {
    getIt.registerLazySingleton<HistoricoCarritoRepository>(
      () => HistoricoCarritoRepositoryImpl(
        getIt<HistoricoCarritoService>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginViewModel>()) {
    getIt.registerFactory<LoginViewModel>(
      () =>
          LoginViewModel(getIt<AuthRepository>(), getIt<ConectividadService>()),
    );
  }

  if (!getIt.isRegistered<CuentaViewModel>()) {
    getIt.registerFactory<CuentaViewModel>(
      () =>
          CuentaViewModel(getIt<AuthRepository>(), getIt<CarritoRepository>()),
    );
  }

  if (!getIt.isRegistered<CrearProductoViewModel>()) {
    getIt.registerFactory<CrearProductoViewModel>(
      () => CrearProductoViewModel(
        getIt<ProductRepository>(),
        getIt<AuthRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<EditarProductoViewModel>()) {
    getIt.registerFactory<EditarProductoViewModel>(
      () => EditarProductoViewModel(
        getIt<ProductRepository>(),
        getIt<AuthRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<EliminarProductoViewModel>()) {
    getIt.registerFactory<EliminarProductoViewModel>(
      () => EliminarProductoViewModel(
        getIt<ProductRepository>(),
        getIt<AuthRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<AgregarCarritoViewModel>()) {
    getIt.registerFactory<AgregarCarritoViewModel>(
      () => AgregarCarritoViewModel(
        getIt<CarritoRepository>(),
        getIt<AuthRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<CarritoViewModel>()) {
    getIt.registerFactory<CarritoViewModel>(
      () => CarritoViewModel(
        getIt<CarritoRepository>(),
        getIt<GestionCarritoRepository>(),
        getIt<AuthRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<UsuariosViewModel>()) {
    getIt.registerFactory<UsuariosViewModel>(
      () => UsuariosViewModel(getIt<UsuarioRepository>()),
    );
  }

  if (!getIt.isRegistered<CarritosViewModel>()) {
    getIt.registerFactory<CarritosViewModel>(
      () => CarritosViewModel(getIt<HistoricoCarritoRepository>()),
    );
  }
}
