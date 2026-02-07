import 'package:flutter/material.dart';
import 'package:conet_app/feature/welcome/widgets/welcome_logo.dart';
import 'package:conet_app/feature/welcome/widgets/welcome_title.dart';
import 'package:conet_app/feature/welcome/widgets/welcome_actions.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
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
    );
  }
}
