import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PostMediaDownloadButton extends StatelessWidget {
  final String mediaUrl;
  final Color iconColor;
  final Color backgroundColor;

  const PostMediaDownloadButton({
    super.key,
    required this.mediaUrl,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x70000000),
  });

  Future<void> _download(BuildContext context) async {
    final uri = Uri.tryParse(mediaUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid media URL')));
      }
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open download link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _download(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FaIcon(FontAwesomeIcons.download, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
