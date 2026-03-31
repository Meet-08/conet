import 'dart:async';

import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/widgets/welcome/welcome_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  static const List<_WelcomeSlide> _slides = [
    _WelcomeSlide(
      imagePath: 'assets/onboarding_images/post_illustration.png',
      title: 'Campus Buzz',
      description: 'Catch real updates, discussions, memes and moments.',
    ),
    _WelcomeSlide(
      imagePath: 'assets/onboarding_images/event_illustration.png',
      title: 'Happenings Nearby',
      description: 'See what is going on or just see who is around.',
    ),
    _WelcomeSlide(
      imagePath: 'assets/onboarding_images/chat_illustration.png',
      title: 'Your Circle',
      description: 'Talk to friends, join groups, and share thoughts.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Intentionally no-op: auth side effects are handled by route guards.
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: AppSpace.s40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.s16),
                    child: Text(
                      'Welcome to Conet',
                      style: AppTextStyles.display,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.s16,
                                ),
                                child: Image.asset(
                                  slide.imagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s12),
                            Text(
                              slide.title,
                              style: textTheme.titleMedium?.copyWith(
                                color: semantic.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpace.s8),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: semantic.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s4,
                        ),
                        width: isActive ? AppSpace.s16 : AppSpace.s6,
                        height: AppSpace.s6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? NeutralPaletteLight.c300
                              : semantic.backgroundDisabled,
                          borderRadius: AppRadius.fullAll,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpace.s32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.s16),
                    child: WelcomeActions(),
                  ),
                  const SizedBox(height: AppSpace.s40),
                ],
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

class _WelcomeSlide {
  final String imagePath;
  final String title;
  final String description;

  const _WelcomeSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
