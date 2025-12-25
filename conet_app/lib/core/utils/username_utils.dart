import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> generateUniqueUsername(
  String firstName,
  String? lastName,
  SupabaseClient supabaseClient,
) async {
  String username = _generateBaseUsername(firstName, lastName);
  String uniqueUsername = username;

  while (await _usernameExists(uniqueUsername, supabaseClient)) {
    final randomDigits = _generateRandomFourDigits();
    uniqueUsername = '$username$randomDigits';
  }

  return uniqueUsername;
}

String _generateBaseUsername(String firstName, String? lastName) {
  String base = firstName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (lastName != null && lastName.isNotEmpty) {
    base += ".${lastName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}";
  }
  return base;
}

Future<bool> _usernameExists(
  String username,
  SupabaseClient supabaseClient,
) async {
  final response = await supabaseClient.rpc(
    'username_exists',
    params: {'p_username': username},
  );

  return response as bool;
}

String _generateRandomFourDigits() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString();
}
