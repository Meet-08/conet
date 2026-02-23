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
    ..registerFactory<UserLogout>(
      () => UserLogout(serviceLocator<AuthRepository>()),
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
        userLogout: serviceLocator<UserLogout>(),
        appUserCubit: serviceLocator<AppUserCubit>(),
        presenceService: serviceLocator<PresenceService>(),
      ),
    );
}

void _initPost() {
  serviceLocator.registerLazySingleton(
    () =>
        DioClient(dio: Dio(), supabaseClient: serviceLocator<SupabaseClient>()),
  );

  // Core - File Upload
  serviceLocator.registerFactory<FileUploadDataSource>(
    () => SupabaseFileUploadDataSource(
      supabaseClient: serviceLocator<SupabaseClient>(),
    ),
  );

  serviceLocator.registerLazySingleton<FileDataSource>(
    () => SupabaseFileDataSource(
      fileUploadDataSource: serviceLocator<FileUploadDataSource>(),
    ),
  );

  // Local data source — Bookmark (Hive). Box is opened in initDependencies().
  serviceLocator.registerLazySingleton<PostBookmarkLocalDataSource>(
    () => PostBookmarkLocalDataSourceImpl(),
  );

  // Remote data source
  serviceLocator.registerFactory<PostDataSource>(
    () => PostDataSourceImpl(
      dioClient: serviceLocator<DioClient>(),
      fileDataSource: serviceLocator<FileDataSource>(),
      supabaseClient: serviceLocator<SupabaseClient>(),
    ),
  );

  // Repository (singleton!) — combines remote + local data sources
  serviceLocator.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      postDataSource: serviceLocator(),
      bookmarkLocalDataSource: serviceLocator(),
    ),
  );

  // Use cases
  serviceLocator.registerFactory(
    () => PostGetPosts(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostGetUserPosts(postRepository: serviceLocator()),
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
  serviceLocator.registerFactory(
    () => PostWatchPostComments(postRepository: serviceLocator()),
  );
  // Bookmark use cases
  serviceLocator.registerFactory(
    () => PostBookmark(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostRemoveBookmark(postRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => PostGetBookmarks(postRepository: serviceLocator()),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => PostBloc(
      getPosts: serviceLocator(),
      getUserPosts: serviceLocator(),
      createPost: serviceLocator(),
      deletePost: serviceLocator(),
      toggleLike: serviceLocator(),
      commentPost: serviceLocator(),
      getPostComments: serviceLocator(),
      bookmarkPost: serviceLocator(),
      removeBookmark: serviceLocator(),
      getBookmarks: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => PostGetLikedPosts(postRepository: serviceLocator()),
  );

  serviceLocator.registerFactory(
    () => PostDetailBloc(
      getPostComments: serviceLocator(),
      watchPostComments: serviceLocator(),
      commentPost: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => LikedPostsBloc(getLikedPosts: serviceLocator()),
  );
}

void _initMessage() {
  // Data Source
  serviceLocator.registerFactory<MessageDataSource>(
    () => MessageDataSourceImpl(
      dioClient: serviceLocator<DioClient>(),
      realTimeDatasource: serviceLocator<MessageRealTimeDatasource>(),
    ),
  );

  serviceLocator.registerFactory<MessageRealTimeDatasource>(
    () =>
        SupabaseMessageRealTimeDataSourceImpl(supabaseClient: serviceLocator()),
  );

  // Message feature repositories
  serviceLocator.registerFactory<MessageRepository>(
    () => MessageRepositoryImpl(
      messageDataSource: serviceLocator(),
      messageRealTimeDatasource: serviceLocator(),
      fileUploadDataSource: serviceLocator(),
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
    () => MessageSearchUsers(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageWatchMessages(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageWatchConversationUpdates(messageRepository: serviceLocator()),
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
      watchConversationUpdates: serviceLocator(),
      searchUsers: serviceLocator(),
    ),
  );
}

void _initProfile() {
  serviceLocator
    // ..registerFactory<ProfileDataSource>(
    //   () => SupabaseProfileDataSource(
    //     supabaseClient: serviceLocator(),
    //     fileUploadDataSource: serviceLocator(),
    //   ),
    // )
    ..registerLazySingleton<ProfileDataSource>(
      () => ProfileDataSourceImpl(
        fileDataSource: serviceLocator(),
        dioClient: serviceLocator(),
      ),
    )
    ..registerLazySingleton<UserProfileRepository>(
      () => UserProfileRepositoryImpl(profileDataSource: serviceLocator()),
    )
    // Use Cases
    ..registerFactory(
      () => ProfileUpdatePersonalInfo(repository: serviceLocator()),
    )
    ..registerFactory(() => ProfileUpdateAboutMe(repository: serviceLocator()))
    ..registerFactory(
      () => ProfileUpdateInterests(repository: serviceLocator()),
    )
    ..registerFactory(
      () => ProfileUpdateAcademicInfo(repository: serviceLocator()),
    )
    ..registerFactory(
      () => ProfileUpdateSocialLinks(repository: serviceLocator()),
    )
    ..registerFactory(() => ProfileUpdatePictures(repository: serviceLocator()))
    ..registerFactory(
      () => ProfileGetUser(userProfileRepository: serviceLocator()),
    )
    ..registerFactory(() => ProfileFollowUser(repository: serviceLocator()))
    ..registerFactory(() => ProfileUnfollowUser(repository: serviceLocator()))
    // Bloc
    ..registerFactory(
      () => ProfileBloc(
        updatePersonalInfo: serviceLocator(),
        updateAboutMe: serviceLocator(),
        updateInterests: serviceLocator(),
        updateAcademicInfo: serviceLocator(),
        updateSocialLinks: serviceLocator(),
        updatePictures: serviceLocator(),
        getUser: serviceLocator(),
        followUser: serviceLocator(),
        unfollowUser: serviceLocator(),
      ),
    );
}
