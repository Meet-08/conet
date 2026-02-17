import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/router/app_router.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var logger = Logger(level: kDebugMode ? .debug : .error);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        BlocProvider(create: (_) => serviceLocator<AuthBloc>()),
        BlocProvider(create: (_) => serviceLocator<PostBloc>()),
        BlocProvider(create: (_) => serviceLocator<MessageBloc>()),
        BlocProvider(create: (_) => serviceLocator<ProfileBloc>()),
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

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthIsUserLoggedIn());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Conet App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
