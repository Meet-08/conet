import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/data_source/supabase_data_source_impl.dart';
import 'package:conet_app/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'init_dependencies.main.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initAuth();

  // Register Supabase client
  serviceLocator.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Core
  serviceLocator.registerLazySingleton<AppUserCubit>(() => AppUserCubit());
}
