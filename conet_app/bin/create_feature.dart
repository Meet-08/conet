// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run bin/create_feature.dart <feature_name>');
    exit(1);
  }

  final featureName = args[0].toLowerCase();
  final baseDir = 'lib/feature/$featureName';

  final dirs = [
    '$baseDir/data/data_sources',
    '$baseDir/data/models',
    '$baseDir/data/repositories',
    '$baseDir/domain/repositories',
    '$baseDir/domain/entities',
    '$baseDir/domain/usecases',
    '$baseDir/presentation/bloc',
    '$baseDir/presentation/pages',
    '$baseDir/presentation/widgets',
  ];

  print('Creating feature structure for: $featureName');

  for (final dir in dirs) {
    final directory = Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      print('Created: $dir');
    } else {
      print('Exists: $dir');
    }
  }

  print('\nFeature "$featureName" structure created successfully!');
}
