import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddDetailsHeader extends StatelessWidget {
  final bool isGoogle;

  const AddDetailsHeader({super.key, this.isGoogle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => {context.read<AuthBloc>().add(AuthLogout())},
          child: const Row(
            children: [
              Icon(FontAwesomeIcons.arrowLeft, size: 20),
              SizedBox(width: 6),
              Text('Back'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Complete Your Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          isGoogle
              ? 'Add your name and choose a username'
              : 'Set up your password and username',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
