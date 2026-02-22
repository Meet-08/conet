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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FontAwesomeIcons.xmark,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
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
                  onTap: () {},
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: 0.5,
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
    final color = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFF64748B);
    final iconBgColor = isDestructive
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF8FAFC);
    final titleColor = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFF334155);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: isDestructive
          ? null
          : const Icon(
              FontAwesomeIcons.chevronRight,
              color: Color(0xFFCBD5E1),
              size: 16,
            ),
      onTap: onTap,
    );
  }
}
