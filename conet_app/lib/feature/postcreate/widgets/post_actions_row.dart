import 'package:flutter/material.dart';

class PostActionsRow extends StatelessWidget {
  const PostActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.image_outlined),
        SizedBox(width: 16),
        Icon(Icons.format_bold),
        SizedBox(width: 16),
        Icon(Icons.format_italic),
        SizedBox(width: 16),
        Icon(Icons.bar_chart),
      ],
    );
  }
}
