import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/router/app_router.dart';
import 'package:conet_app/core/services/presence_service.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/firebase_options.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var logger = Logger(level: kDebugMode ? .debug : .error);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: kDebugMode,
  );

  await initDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<AppUserCubit>()),
        BlocProvider(create: (_) => serviceLocator<PresenceCubit>()),
        BlocProvider(create: (_) => serviceLocator<AuthBloc>()),
        BlocProvider(create: (_) => serviceLocator<PostBloc>()),
        BlocProvider(create: (_) => serviceLocator<MessageBloc>()),
        BlocProvider(create: (_) => serviceLocator<NotificationBloc>()),
        BlocProvider(create: (_) => serviceLocator<ProfileBloc>()),
        BlocProvider(create: (_) => serviceLocator<EventBloc>()),
        BlocProvider(create: (_) => serviceLocator<EventRegistrationBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthIsUserLoggedIn());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final presenceService = serviceLocator<PresenceService>();
    final appUserCubit = serviceLocator<AppUserCubit>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // User is leaving the app — untrack presence immediately
        presenceService.dispose();
        break;
      case AppLifecycleState.resumed:
        // User returned — re-track if still logged in
        final userState = appUserCubit.state;
        if (userState is AppUserAuthenticated) {
          presenceService.start(userState.user.id);
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUserCubit, AppUserState>(
      listener: (context, state) {
        if (state is AppUserAuthenticated) {
          context.read<NotificationBloc>().add(const NotificationLoadEvent());
        }
      },
      child: MaterialApp.router(
        title: 'Conet App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.black26),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
