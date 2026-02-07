import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.black,
      onPressed: () => context.push('/create-post'),
      child: const Icon(Icons.add, size: 28, color: Colors.white),
    );
  }
}
