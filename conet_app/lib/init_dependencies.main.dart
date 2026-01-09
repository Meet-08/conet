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
  serviceLocator.registerLazySingleton(
    () =>
        DioClient(dio: Dio(), supabaseClient: serviceLocator<SupabaseClient>()),
  );

  serviceLocator.registerLazySingleton<FileDataSource>(
    () => SupabaseFileDataSource(
      supabaseClient: serviceLocator<SupabaseClient>(),
    ),
  );

  // Data sources
  serviceLocator.registerFactory<PostDataSource>(
    () => PostDataSourceImpl(
      dioClient: serviceLocator<DioClient>(),
      fileDataSource: serviceLocator<FileDataSource>(),
    ),
  );

  serviceLocator.registerFactory<PostRealtimeDataSource>(
    () => SupabasePostRealTimeDatasourceImpl(supabaseClient: serviceLocator()),
  );

  // Repository (singleton!)
  serviceLocator.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      postDataSource: serviceLocator(),
      postRealtimeSource: serviceLocator(),
    ),
  );

  // Use cases
  serviceLocator.registerFactory(
    () => PostGetPosts(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostWatchPosts(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostCreate(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostDelete(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostToggleLike(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostComment(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostGetPostComments(postRepository: serviceLocator()),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => PostBloc(
      getPosts: serviceLocator(),
      watchPosts: serviceLocator(),
      createPost: serviceLocator(),
      deletePost: serviceLocator(),
      toggleLike: serviceLocator(),
      commentPost: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => PostDetailBloc(
      getPostComments: serviceLocator(),
      commentPost: serviceLocator(),
    ),
  );
}

void _initMessage() {
  // Data Source
  serviceLocator.registerFactory<MessageDataSource>(
    () => SupabaseMessageDataSourceImpl(serviceLocator()),
  );

  serviceLocator.registerFactory<MessageRealTimeDatasource>(
    () =>
        SupabaseMessageRealTimeDataSourceImpl(supabaseClient: serviceLocator()),
  );

  // Repository
  serviceLocator.registerFactory<MessageRepository>(
    () => MessageRepositoryImpl(
      messageDataSource: serviceLocator(),
      messageRealTimeDatasource: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => MessageGetConversations(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageCreateConversation(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageGetMessages(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageSendMessage(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageMarkAsRead(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageWatchMessages(messageRepository: serviceLocator()),
  );

  // Bloc
  serviceLocator.registerLazySingleton(
    () => MessageBloc(
      createConversation: serviceLocator(),
      getConversationsUsecase: serviceLocator(),
      getMessages: serviceLocator(),
      sendMessage: serviceLocator(),
      markAsRead: serviceLocator(),
      watchMessages: serviceLocator(),
    ),
  );
}
