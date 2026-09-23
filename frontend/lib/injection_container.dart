import 'package:get_it/get_it.dart';

import 'core/cubit/connectivity_cubit.dart';
import 'core/network/api_client.dart';
import 'core/storage/prefs_storage.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/utils/file_picker_helper.dart';
import 'features/admin/applications/data/repositories/admin_application_repository.dart';
import 'features/admin/claims/data/repositories/admin_claim_repository.dart';
import 'features/admin/dashboard/data/repositories/admin_dashboard_repository.dart';
import 'features/admin/farmers/data/repositories/admin_farmer_repository.dart';
import 'features/admin/schemes/data/repositories/admin_scheme_repository.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_farmer_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/sync_user_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/farmer/animals/data/repositories/animal_repository.dart';
import 'features/farmer/applications/data/repositories/application_repository.dart';
import 'features/farmer/claims/data/repositories/claim_repository.dart';
import 'features/farmer/profile/data/repositories/profile_repository.dart';
import 'features/farmer/schemes/data/repositories/scheme_repository.dart';

final GetIt sl = GetIt.instance;

/// Wires everything once, from main(). Screen-scoped cubits are created by the
/// widgets that own them, so they are not registered here.
Future<void> configureDependencies() async {
  // --- Storage --------------------------------------------------------------
  sl.registerLazySingleton<SecureStorage>(SecureStorage.new);
  sl.registerSingleton<PrefsStorage>(await PrefsStorage.init());

  // --- Network --------------------------------------------------------------
  sl.registerLazySingleton<ApiClient>(() => ApiClient(secureStorage: sl()));

  // --- Utilities ------------------------------------------------------------
  sl.registerLazySingleton<FilePickerHelper>(FilePickerHelper.new);

  // --- Auth -----------------------------------------------------------------
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<RegisterFarmerUseCase>(() => RegisterFarmerUseCase(sl()));
  sl.registerLazySingleton<SyncUserUseCase>(() => SyncUserUseCase(sl()));
  sl.registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(sl()));

  // --- Feature repositories -------------------------------------------------
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(sl()));
  sl.registerLazySingleton<AnimalRepository>(() => AnimalRepository(sl()));
  sl.registerLazySingleton<SchemeRepository>(() => SchemeRepository(sl()));
  sl.registerLazySingleton<ApplicationRepository>(() => ApplicationRepository(sl()));
  sl.registerLazySingleton<ClaimRepository>(() => ClaimRepository(sl()));
  sl.registerLazySingleton<AdminSchemeRepository>(() => AdminSchemeRepository(sl()));
  sl.registerLazySingleton<AdminApplicationRepository>(() => AdminApplicationRepository(sl()));
  sl.registerLazySingleton<AdminClaimRepository>(() => AdminClaimRepository(sl()));
  sl.registerLazySingleton<AdminFarmerRepository>(() => AdminFarmerRepository(sl()));
  sl.registerLazySingleton<AdminDashboardRepository>(() => AdminDashboardRepository(sl()));

  // --- App-wide cubits ------------------------------------------------------
  // AuthCubit is a singleton because GoRouter's redirect reads its state.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      login: sl(),
      registerFarmer: sl(),
      getCurrentUser: sl(),
      logout: sl(),
      resetPassword: sl(),
    ),
  );
  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
  sl.registerLazySingleton<ConnectivityCubit>(ConnectivityCubit.new);
}
