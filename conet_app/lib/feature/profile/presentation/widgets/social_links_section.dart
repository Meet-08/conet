import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksSection extends StatelessWidget {
  final List<SocialLinks> socialLinks;

  const SocialLinksSection({super.key, required this.socialLinks});

  IconData _getIconForLink(String name) {
    switch (name.toLowerCase()) {
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'github':
        return FontAwesomeIcons.github;
      case 'twitter':
      case 'x':
        return FontAwesomeIcons.xTwitter;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'website':
      case 'portfolio':
        return FontAwesomeIcons.globe;
      default:
        return FontAwesomeIcons.link;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) return const SizedBox.shrink();

    return Row(
      children: socialLinks.map((link) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => _launchUrl(link.link),
            child: Icon(
              _getIconForLink(link.name),
              size: 20,
              color: Colors.grey.shade700,
            ),
          ),
        );
      }).toList(),
    );
  }
}
