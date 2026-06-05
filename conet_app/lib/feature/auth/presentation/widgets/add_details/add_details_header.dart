import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddDetailsHeader extends StatelessWidget {
  final bool isGoogle;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;

  const AddDetailsHeader({
    super.key,
    this.isGoogle = true,
    this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack ?? () => context.read<AuthBloc>().add(AuthLogout()),
          child: const Row(
            children: [
              FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
              SizedBox(width: 6),
              Text('Back'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title ?? 'Complete Your Profile',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle ??
              (isGoogle
                  ? 'Add your name and choose a username'
                  : 'Set up your password and username'),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
