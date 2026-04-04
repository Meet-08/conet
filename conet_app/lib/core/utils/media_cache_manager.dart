import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MediaCacheManager {
  static const _cacheKey = 'conetMediaCache';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 300,
    ),
  );
}
