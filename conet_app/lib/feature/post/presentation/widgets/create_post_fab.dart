import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: RoundedSuperellipseBorder(borderRadius: .circular(60)),
      backgroundColor: Colors.black,
      onPressed: () => context.push('/create-post'),
      child: const Icon(FontAwesomeIcons.plus, size: 22, color: Colors.white),
    );
  }
}
