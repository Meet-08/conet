part of 'init_dependencies.dart';

void _initAuth() {
  // Data Source
  serviceLocator
    ..registerFactory<AuthDataSource>(
      () => SupabaseDataSourceImpl(
        supabaseClient: serviceLocator<SupabaseClient>(),
      ),
    )
    // Repository
    ..registerFactory<AuthRepository>(
      () =>
          AuthRepositoryImpl(authDataSource: serviceLocator<AuthDataSource>()),
    )
    // Use Cases
    ..registerFactory<UserLogin>(
      () => UserLogin(authRepository: serviceLocator<AuthRepository>()),
    )
    ..registerFactory<UserVerifyOtp>(
      () => UserVerifyOtp(authRepository: serviceLocator<AuthRepository>()),
    )
    ..registerFactory<UserSigninWithGoogle>(
      () => UserSigninWithGoogle(
        authRepository: serviceLocator<AuthRepository>(),
      ),
    )
    ..registerFactory<UserSendOtp>(
      () => UserSendOtp(authRepository: serviceLocator<AuthRepository>()),
    )
    ..registerFactory<UserCurrent>(
      () => UserCurrent(authRepository: serviceLocator<AuthRepository>()),
    )
    ..registerFactory<UserAddDetails>(
      () => UserAddDetails(authRepository: serviceLocator<AuthRepository>()),
    )
    // Bloc
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        userLogin: serviceLocator<UserLogin>(),
        userSendOtp: serviceLocator<UserSendOtp>(),
        userSigninWithGoogle: serviceLocator<UserSigninWithGoogle>(),
        userVerifyOtp: serviceLocator<UserVerifyOtp>(),
        userCurrent: serviceLocator<UserCurrent>(),
        userAddDetails: serviceLocator<UserAddDetails>(),
        appUserCubit: serviceLocator<AppUserCubit>(),
      ),
    );
}

void _initPost() {
  // Data Source
  serviceLocator
    ..registerLazySingleton<DioClient>(
      () => DioClient(
        dio: Dio(),
        supabaseClient: serviceLocator<SupabaseClient>(),
      ),
    )
    ..registerLazySingleton<FileDataSource>(
      () => SupabaseFileDataSource(
        supabaseClient: serviceLocator<SupabaseClient>(),
      ),
    )
    ..registerFactory<PostDataSource>(
      () => PostDataSourceImpl(
        dioClient: serviceLocator<DioClient>(),
        fileDataSource: serviceLocator<FileDataSource>(),
      ),
    )
    // Repository
    ..registerFactory<PostRepository>(
      () =>
          PostRepositoryImpl(postDataSource: serviceLocator<PostDataSource>()),
    )
    // Use Cases
    ..registerFactory<PostCreate>(
      () => PostCreate(postRepository: serviceLocator<PostRepository>()),
    )
    ..registerFactory<PostDelete>(
      () => PostDelete(postRepository: serviceLocator<PostRepository>()),
    )
    ..registerFactory<PostGetPosts>(
      () => PostGetPosts(postRepository: serviceLocator<PostRepository>()),
    )
    ..registerFactory(
      () => PostComment(postRepository: serviceLocator<PostRepository>()),
    )
    ..registerFactory<PostToggleLike>(
      () => PostToggleLike(postRepository: serviceLocator<PostRepository>()),
    )
    // Bloc
    ..registerLazySingleton<PostBloc>(
      () => PostBloc(
        getPosts: serviceLocator<PostGetPosts>(),
        createPost: serviceLocator<PostCreate>(),
        deletePost: serviceLocator<PostDelete>(),
        toggleLike: serviceLocator<PostToggleLike>(),
        commentPost: serviceLocator<PostComment>(),
      ),
    );
}
