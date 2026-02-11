import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
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
      final key = '${a.collegeName}|${a.course}|${a.major}';
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
                icon: const Icon(Icons.edit_outlined, size: 16),
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
                      Icon(
                        Icons.school_outlined,
                        size: 16,
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
                      Icon(
                        Icons.menu_book_outlined,
                        size: 16,
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
    final parts = <String>[academic.course];
    if (academic.major != null && academic.major!.isNotEmpty) {
      parts.add(academic.major!);
    }
    if (academic.startYear != null && academic.endYear != null) {
      final currentYear = DateTime.now().year;
      final int yearInCourse = (currentYear - academic.startYear! + 1).toInt();
      if (yearInCourse > 0 &&
          yearInCourse <= (academic.endYear! - academic.startYear! + 1)) {
        parts.add('${_ordinal(yearInCourse)} year');
      }
    }
    return parts.join(' · ');
  }

  String _ordinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
