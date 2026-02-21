import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/welcome_actions.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/welcome_logo.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/welcome_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // The if condition was removed as per instruction.
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(flex: 2),
                    WelcomeLogo(),
                    Spacer(),
                    WelcomeTitle(),
                    Spacer(flex: 2),
                    WelcomeActions(),
                    Spacer(),
                  ],
                ),
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Center(child: Loader());
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
