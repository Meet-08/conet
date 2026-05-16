import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/data_sources/presence_data_source.dart';
import 'package:conet_app/core/common/data_sources/supabase_file_upload_data_source.dart';
import 'package:conet_app/core/common/data_sources/supabase_presence_data_source.dart';
import 'package:conet_app/core/common/usecases/user_search_users.dart';
import 'package:conet_app/core/router/app_router.dart';
import 'package:conet_app/core/services/device_service.dart';
import 'package:conet_app/core/services/notification_config_service.dart';
import 'package:conet_app/core/services/presence_service.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/data_source/supabase_data_source_impl.dart';
import 'package:conet_app/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_logout.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/device/data/data_source/device_remote_data_source.dart';
import 'package:conet_app/feature/device/data/repository/device_repository_impl.dart';
import 'package:conet_app/feature/device/domain/repository/device_repository.dart';
import 'package:conet_app/feature/device/domain/usecases/register_device_usecase.dart';
import 'package:conet_app/feature/device/domain/usecases/remove_device_usecase.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source_impl.dart';
import 'package:conet_app/feature/event/data/repositories/event_repository_impl.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_attendees.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_organized_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_published_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_info.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_college.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_course.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_trend_by_date.dart';
import 'package:conet_app/feature/event/domain/usecases/event_mark_attendance.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_register.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save_draft.dart';
import 'package:conet_app/feature/event/domain/usecases/event_setup_organizer_resources.dart';
import 'package:conet_app/feature/event/domain/usecases/event_update.dart';
import 'package:conet_app/feature/event/domain/usecases/event_update_draft.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_analytics_bloc.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source_impl.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/data_sources/supabase_message_real_time_data_source_impl.dart';
import 'package:conet_app/feature/message/data/repositories/message_repository_impl.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/fetch_shared_content.dart';
import 'package:conet_app/feature/message/domain/usecases/message_add_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_conversation.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_delete_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_demote_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_conversations.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_group_members.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_messages.dart';
import 'package:conet_app/feature/message/domain/usecases/message_mark_as_read.dart';
import 'package:conet_app/feature/message/domain/usecases/message_promote_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_remove_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_send_message.dart';
import 'package:conet_app/feature/message/domain/usecases/message_update_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_conversation_updates.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_messages.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_data_source.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_data_source_impl.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_realtime_data_source.dart';
import 'package:conet_app/feature/notification/data/data_sources/supabase_notification_realtime_data_source_impl.dart';
import 'package:conet_app/feature/notification/data/repositories/notification_repository_impl.dart';
import 'package:conet_app/feature/notification/domain/repositories/notification_repository.dart';
import 'package:conet_app/feature/notification/domain/usecases/get_notifications_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/mark_all_as_seen_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/watch_notifications_usecase.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:conet_app/feature/payment/data/data_sources/payment_data_source.dart';
import 'package:conet_app/feature/payment/data/repositories/payment_repository_impl.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:conet_app/feature/payment/domain/usecases/create_organizer_account.dart';
import 'package:conet_app/feature/payment/domain/usecases/get_organizer_account.dart';
import 'package:conet_app/feature/payment/domain/usecases/initiate_payment.dart';
import 'package:conet_app/feature/payment/domain/usecases/revert_registration.dart';
import 'package:conet_app/feature/payment/presentation/bloc/payment_bloc.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_bookmark_local_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_bookmark_local_data_source_impl.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source_impl.dart';
import 'package:conet_app/feature/post/data/data_sources/supabase_file_data_source.dart';
import 'package:conet_app/feature/post/data/repositories/post_repository_impl.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_bookmarks.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_liked_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_user_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_remove_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_post_comments.dart';
import 'package:conet_app/feature/post/presentation/bloc/liked_posts_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source_impl.dart';
import 'package:conet_app/feature/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_follow_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_followers.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_following.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_unfollow_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_about_me.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_interests.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_personal_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_pictures.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_social_links.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_connections_bloc.dart';
import 'package:conet_app/feature/report/data/data_sources/report_data_source.dart';
import 'package:conet_app/feature/report/data/data_sources/report_data_source_impl.dart';
import 'package:conet_app/feature/report/data/repositories/report_repository_impl.dart';
import 'package:conet_app/feature/report/domain/repositories/report_repository.dart';
import 'package:conet_app/feature/report/domain/usecases/create_report.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'init_dependencies.main.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();
  await Hive.openBox(PostBookmarkLocalDataSourceImpl.boxName);

  serviceLocator.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  serviceLocator.registerLazySingleton<AppUserCubit>(() => AppUserCubit());
  serviceLocator.registerLazySingleton<PresenceCubit>(() => PresenceCubit());

  serviceLocator.registerLazySingleton<PresenceDataSource>(
    () => SupabasePresenceDataSource(
      supabaseClient: serviceLocator<SupabaseClient>(),
    ),
  );
  serviceLocator.registerLazySingleton<PresenceService>(
    () => PresenceService(
      presenceDataSource: serviceLocator<PresenceDataSource>(),
      presenceCubit: serviceLocator<PresenceCubit>(),
      appUserCubit: serviceLocator<AppUserCubit>(),
    ),
  );

  // Initialize features after core dependencies are registered
  _initAuth();
  _initPost();
  _initReport();
  _initMessage();
  _initProfile();
  _initDevice();
  _initNotification();
  _initEvent();
  _initPayment();

  await serviceLocator<NotificationConfigService>().init();
}
