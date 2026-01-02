import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/data_source/supabase_data_source_impl.dart';
import 'package:conet_app/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_real_time_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/supabase_file_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/supabase_post_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/supabase_post_real_time_datasource_impl.dart';
import 'package:conet_app/feature/post/data/repositories/post_repository_impl.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_posts.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'init_dependencies.main.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // Register Supabase client first (required by other dependencies)
  serviceLocator.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Core
  serviceLocator.registerLazySingleton<AppUserCubit>(() => AppUserCubit());

  // Initialize features after core dependencies are registered
  _initAuth();
  _initPost();
}
