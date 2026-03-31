import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.xmark,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.headingH3.copyWith(
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textPrimary,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.borderSubtle,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSectionHeader('Your Activity'),
                _buildListTile(
                  icon: FontAwesomeIcons.bookmark,
                  title: 'Saved Posts',
                  onTap: () => context.push("/saved-posts"),
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.heart,
                  title: 'Liked Posts',
                  onTap: () => context.push("/liked-posts"),
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.comment,
                  title: 'Your Comments',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Preferences'),
                _buildListTile(
                  icon: FontAwesomeIcons.user,
                  title: 'Edit Profile',
                  onTap: () => context.push('/edit-profile'),
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.lock,
                  title: 'Privacy & Security',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.bell,
                  title: 'Notifications',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Support & Info'),
                _buildListTile(
                  icon: FontAwesomeIcons.circleQuestion,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.fileLines,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: FontAwesomeIcons.shieldHalved,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Session'),
                _buildListTile(
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () => context.read<AuthBloc>().add(AuthLogout()),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          title,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(
              context,
            ).extension<AppSemanticColors>()!.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Builder(
      builder: (context) {
        final semanticColors = Theme.of(
          context,
        ).extension<AppSemanticColors>()!;
        final color = isDestructive
            ? semanticColors.textError
            : semanticColors.textSecondary;
        final iconBgColor = isDestructive
            ? semanticColors.backgroundError
            : semanticColors.backgroundSecondary;
        final titleColor = isDestructive
            ? semanticColors.textError
            : semanticColors.textPrimary;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 0,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyDefault.copyWith(
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          trailing: isDestructive
              ? null
              : FaIcon(
                  FontAwesomeIcons.chevronRight,
                  color: semanticColors.borderSubtle,
                  size: 16,
                ),
          onTap: onTap,
        );
      },
    );
  }
}
