import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileHeaderCard({super.key, required this.userProfile});

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
                color: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.backgroundTertiary,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: CustomCircleAvatar(
                  size: CustomCircleAvatarSize.medium,
                  radius: 42,
                  imageUrl: userProfile.profilePicUrl,
                  displayName: _fullName,
                  userId: userProfile.id,
                  backgroundColor: Theme.of(
                    context,
                  ).extension<AppSemanticColors>()!.backgroundTertiary,
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
              Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).extension<AppSemanticColors>()!.textPrimary,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.borderDefault,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: AppTextStyles.caption,
                  ),
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
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.textSecondary,
              ),
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
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.5,
                color: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.textBrand,
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
                        color: Theme.of(
                          context,
                        ).extension<AppSemanticColors>()!.iconSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          academic.collegeName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).extension<AppSemanticColors>()!.textPrimary,
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
                        color: Theme.of(
                          context,
                        ).extension<AppSemanticColors>()!.iconSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildCourseText(academic),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).extension<AppSemanticColors>()!.textPrimary,
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
      if (academic.startYear != null && academic.endYear != null) {
        buffer.write('-');
      }
      if (academic.endYear != null) buffer.write('${academic.endYear}');
    }
    return buffer.toString();
  }
}
