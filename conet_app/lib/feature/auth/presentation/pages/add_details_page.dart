import 'package:flutter/material.dart';

class AddDetailsPage extends StatelessWidget {
  final bool isGoogle;

  const AddDetailsPage({super.key, this.isGoogle = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Details')),
      body: Center(
        child: Text('Add your profile details (Google sign-in: $isGoogle)'),
      ),
    );
  }
}
