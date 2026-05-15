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
        updateAcademicInfo: serviceLocator<ProfileUpdateAcademicInfo>(),
        userLogout: serviceLocator<UserLogout>(),
        appUserCubit: serviceLocator<AppUserCubit>(),
        presenceService: serviceLocator<PresenceService>(),
        deviceService: serviceLocator<DeviceService>(),
        goToRoute: (path) => AppRouter.router.go(path),
      ),
    );
}

void _initPost() {
  serviceLocator.registerLazySingleton(
    () =>
        DioClient(dio: Dio(), supabaseClient: serviceLocator<SupabaseClient>()),
  );

  serviceLocator.registerFactory(
    () => UserSearchUsers(dioClient: serviceLocator<DioClient>()),
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
    () => PostGetPost(postRepository: serviceLocator()),
  );

  serviceLocator.registerFactory(
    () => PostDetailBloc(
      getPostComments: serviceLocator(),
      watchPostComments: serviceLocator(),
      commentPost: serviceLocator(),
      getPost: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => LikedPostsBloc(getLikedPosts: serviceLocator()),
  );
}

void _initReport() {
  serviceLocator
    ..registerFactory<ReportDataSource>(
      () => ReportDataSourceImpl(dioClient: serviceLocator<DioClient>()),
    )
    ..registerLazySingleton<ReportRepository>(
      () => ReportRepositoryImpl(reportDataSource: serviceLocator()),
    )
    ..registerFactory(() => CreateReport(reportRepository: serviceLocator()))
    ..registerFactory(() => ReportBloc(createReport: serviceLocator()));
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
    () => MessageWatchMessages(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageWatchConversationUpdates(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageCreateGroup(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageUpdateGroup(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageDeleteGroup(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageGetGroupMembers(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageAddGroupMember(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageRemoveGroupMember(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessagePromoteGroupMember(messageRepository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => MessageDemoteGroupMember(messageRepository: serviceLocator()),
  );

  // Use case for fetching shared content (media/docs/posts)
  serviceLocator.registerFactory(
    () => FetchSharedContent(serviceLocator<MessageRepository>()),
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
      createGroup: serviceLocator(),
      updateGroup: serviceLocator(),
      deleteGroup: serviceLocator(),
      getGroupMembers: serviceLocator(),
      addGroupMember: serviceLocator(),
      removeGroupMember: serviceLocator(),
      promoteGroupMember: serviceLocator(),
      demoteGroupMember: serviceLocator(),
      fetchSharedContent: serviceLocator(),
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
        fileUploadDataSource: serviceLocator(),
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
    ..registerFactory(() => ProfileGetFollowers(repository: serviceLocator()))
    ..registerFactory(() => ProfileGetFollowing(repository: serviceLocator()))
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
    )
    ..registerFactory(
      () => ProfileConnectionsBloc(
        getFollowers: serviceLocator(),
        getFollowing: serviceLocator(),
      ),
    );
}

void _initDevice() {
  serviceLocator
    ..registerLazySingleton<NotificationConfigService>(
      () => NotificationConfigService(),
    )
    ..registerFactory<DeviceRemoteDataSource>(
      () => DeviceRemoteDataSourceImpl(serviceLocator<DioClient>()),
    )
    ..registerFactory<DeviceRepository>(
      () => DeviceRepositoryImpl(serviceLocator<DeviceRemoteDataSource>()),
    )
    ..registerFactory<RegisterDeviceUseCase>(
      () => RegisterDeviceUseCase(serviceLocator<DeviceRepository>()),
    )
    ..registerFactory<RemoveDeviceUseCase>(
      () => RemoveDeviceUseCase(serviceLocator<DeviceRepository>()),
    )
    ..registerLazySingleton<DeviceService>(
      () => DeviceService(
        serviceLocator<RegisterDeviceUseCase>(),
        serviceLocator<RemoveDeviceUseCase>(),
        serviceLocator<AppUserCubit>(),
        serviceLocator<NotificationConfigService>(),
      ),
    );
}

void _initEvent() {
  serviceLocator.registerFactory<EventDataSource>(
    () => EventDataSourceImpl(
      dioClient: serviceLocator<DioClient>(),
      fileUploadDataSource: serviceLocator<FileUploadDataSource>(),
    ),
  );

  serviceLocator.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(eventDataSource: serviceLocator()),
  );

  serviceLocator.registerFactory(
    () => EventPublish(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventSaveDraft(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventUpdate(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventUpdateDraft(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventSetupOrganizerResources(
      repository: serviceLocator<EventRepository>(),
    ),
  );
  serviceLocator.registerFactory(
    () => EventGetById(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventRegister(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventSave(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () =>
        EventGetPublishedEvents(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventGetMyEvents(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventGetMyOrganizedEvents(
      repository: serviceLocator<EventRepository>(),
    ),
  );
  serviceLocator.registerFactory(
    () =>
        EventGetRegistrationInfo(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventGetAttendees(repository: serviceLocator<EventRepository>()),
  );
  serviceLocator.registerFactory(
    () => EventMarkAttendance(repository: serviceLocator<EventRepository>()),
  );

  serviceLocator.registerFactory(
    () => EventBloc(
      getById: serviceLocator(),
      getPublishedEvents: serviceLocator(),
      getMyEvents: serviceLocator(),
      getMyOrganizedEvents: serviceLocator(),
      publish: serviceLocator(),
      registerEvent: serviceLocator(),
      saveEvent: serviceLocator(),
      saveDraft: serviceLocator(),
      updateDraft: serviceLocator(),
      updateEvent: serviceLocator(),
      setupOrganizerResources: serviceLocator(),
      createGroup: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => EventRegistrationBloc(
      getAttendees: serviceLocator(),
      getRegistrationInfo: serviceLocator(),
      markAttendance: serviceLocator(),
    ),
  );
}

void _initNotification() {
  // Data Sources
  serviceLocator.registerFactory<NotificationDataSource>(
    () => NotificationDataSourceImpl(dioClient: serviceLocator<DioClient>()),
  );
  serviceLocator.registerFactory<NotificationRealtimeDataSource>(
    () => SupabaseNotificationRealtimeDataSourceImpl(
      supabaseClient: serviceLocator<SupabaseClient>(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<NotificationRepository>(
    () => NotificationRepositoryImpl(
      dataSource: serviceLocator<NotificationDataSource>(),
      realtimeDataSource: serviceLocator<NotificationRealtimeDataSource>(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => GetNotificationsUseCase(
      repository: serviceLocator<NotificationRepository>(),
    ),
  );
  serviceLocator.registerFactory(
    () => MarkAllAsSeenUseCase(
      repository: serviceLocator<NotificationRepository>(),
    ),
  );
  serviceLocator.registerFactory(
    () => WatchNotificationsUseCase(
      repository: serviceLocator<NotificationRepository>(),
    ),
  );

  // Bloc
  serviceLocator.registerLazySingleton(
    () => NotificationBloc(
      getNotifications: serviceLocator<GetNotificationsUseCase>(),
      markAllAsSeen: serviceLocator<MarkAllAsSeenUseCase>(),
      watchNotifications: serviceLocator<WatchNotificationsUseCase>(),
    ),
  );
}

void _initPayment() {
  serviceLocator.registerFactory<PaymentDataSource>(
    () => PaymentDataSourceImpl(serviceLocator<DioClient>()),
  );

  serviceLocator.registerFactory<PaymentRepository>(
    () => PaymentRepositoryImpl(serviceLocator<PaymentDataSource>()),
  );

  serviceLocator.registerFactory(
    () => InitiatePayment(serviceLocator<PaymentRepository>()),
  );

  serviceLocator.registerFactory(
    () => RevertRegistration(serviceLocator<PaymentRepository>()),
  );

  serviceLocator.registerFactory(
    () => CreateOrganizerAccount(serviceLocator<PaymentRepository>()),
  );

  serviceLocator.registerFactory(
    () => GetOrganizerAccount(serviceLocator<PaymentRepository>()),
  );

  serviceLocator.registerFactory(
    () => PaymentBloc(
      initiatePayment: serviceLocator<InitiatePayment>(),
      revertRegistration: serviceLocator<RevertRegistration>(),
      createOrganizerAccount: serviceLocator<CreateOrganizerAccount>(),
      getOrganizerAccount: serviceLocator<GetOrganizerAccount>(),
    ),
  );
}
