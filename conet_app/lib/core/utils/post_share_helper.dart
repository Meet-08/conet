import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';

class PostShareHelper {
  static const String _defaultHost = 'ms-test08.github.io';

  static Uri _resolveDeepLinkBaseUri() {
    final configured = dotenv.env['DEEP_LINK_HOST']?.trim();
    if (configured == null || configured.isEmpty) {
      return Uri(scheme: 'https', host: _defaultHost);
    }

    var value = configured;
    if (value.startsWith('//')) {
      value = 'https:$value';
    } else if (!value.contains('://')) {
      value = 'https://$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.host.isEmpty) {
      return Uri(scheme: 'https', host: _defaultHost);
    }

    final scheme = parsed.scheme.isEmpty ? 'https' : parsed.scheme;
    return Uri(
      scheme: scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: parsed.path,
    );
  }

  static String _resolveBasePath(Uri baseUri) {
    final fromEnv = dotenv.env['DEEP_LINK_BASE_PATH']?.trim();
    final rawPath = (fromEnv == null || fromEnv.isEmpty)
        ? baseUri.path
        : fromEnv;
    if (rawPath.isEmpty || rawPath == '/') return '';
    return rawPath.startsWith('/') ? rawPath : '/$rawPath';
  }

  static String _joinPath(String left, String right) {
    final normalizedLeft = left.endsWith('/')
        ? left.substring(0, left.length - 1)
        : left;
    final normalizedRight = right.startsWith('/') ? right : '/$right';
    return '$normalizedLeft$normalizedRight';
  }

  static Uri buildPostDeepLink(String postId) {
    final baseUri = _resolveDeepLinkBaseUri();
    final basePath = _resolveBasePath(baseUri);
    final postPath = _joinPath(basePath, '/post-detail/$postId');

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: postPath,
    );
  }

  static Future<void> sharePost({
    required String postId,
    required String username,
    required String content,
  }) {
    final deepLink = buildPostDeepLink(postId);
    final trimmed = content.trim();
    final preview = trimmed.length > 100
        ? '${trimmed.substring(0, 100)}...'
        : trimmed;
    final shareText = 'Post by @$username\n$preview\n\n$deepLink';

    return SharePlus.instance.share(ShareParams(text: shareText));
  }
}
