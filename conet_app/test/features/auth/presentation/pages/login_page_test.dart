import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(AuthLogin(email: '', password: ''));
    registerFallbackValue(AuthInitial());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  tearDown(() {
    mockAuthBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('renders login form with email and password fields', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error when password is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets(
      'dispatches AuthLogin when form is valid and login button tapped',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        await tester.tap(find.text('Login').last);
        await tester.pump();

        verify(
          () => mockAuthBloc.add(
            any(
              that: isA<AuthLogin>()
                  .having((e) => e.email, 'email', 'test@example.com')
                  .having((e) => e.password, 'password', 'password123'),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('renders Sign Up link', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(RichText), findsWidgets);
    });
  });
}
