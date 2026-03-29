import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileHeaderCard({super.key, required this.userProfile});

  String get _initials {
    final first = userProfile.firstName?.isNotEmpty == true
        ? userProfile.firstName![0]
        : '';
    final last = userProfile.lastName?.isNotEmpty == true
        ? userProfile.lastName![0]
        : '';
    return '$first$last'.toUpperCase();
  }

  String get _fullName {
    final first = userProfile.firstName ?? '';
    final last = userProfile.lastName ?? '';
    return '$first $last'.trim();
  }

  List<UserAcademics> get _uniqueAcademics {
    final seen = <String>{};
    return userProfile.academics.where((a) {
      final key = '${a.collegeName}|${a.degree}|${a.course}|${a.major}';
      return seen.add(key);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                image: userProfile.bannerImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(userProfile.bannerImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            // Avatar positioned at bottom-left overlapping the banner
            Positioned(
              left: 16,
              bottom: -40,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: userProfile.profilePicUrl != null
                    ? CircleAvatar(
                        radius: 42,
                        backgroundImage: NetworkImage(
                          userProfile.profilePicUrl!,
                        ),
                      )
                    : CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Edit Profile button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/edit-profile'),
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                label: const Text('Edit profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Name
        if (_fullName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
        // Username
        if (userProfile.username != null &&
            userProfile.username!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '@${userProfile.username}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
        // About me
        if (userProfile.aboutMe != null && userProfile.aboutMe!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              userProfile.aboutMe!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.teal.shade700,
              ),
            ),
          ),
        ],
        // Academic info
        if (userProfile.academics.isNotEmpty) ...[
          const SizedBox(height: 14),
          ..._uniqueAcademics.map(
            (academic) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.buildingColumns,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          academic.collegeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.graduationCap,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildCourseText(academic),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _buildCourseText(dynamic academic) {
    final buffer = StringBuffer();
    if (academic.degree != null && academic.degree.toString().isNotEmpty) {
      buffer.write('${academic.degree} • ');
    }
    buffer.write(academic.course);
    if (academic.startYear != null || academic.endYear != null) {
      buffer.write(' • ');
      if (academic.startYear != null) buffer.write('${academic.startYear}');
      if (academic.startYear != null && academic.endYear != null) buffer.write('-');
      if (academic.endYear != null) buffer.write('${academic.endYear}');
    }
    return buffer.toString();
  }
}
