import 'package:conet_app/core/common/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultPage extends StatelessWidget {
  final User user;

  const ResultPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Successful'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              // Success Title
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been verified successfully',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // User Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        backgroundImage: user.profilePicUrl.isNotEmpty
                            ? NetworkImage(user.profilePicUrl)
                            : null,
                        child: user.profilePicUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Section Title
                    Text(
                      'User Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // User ID
                    _buildDetailRow(
                      context,
                      icon: Icons.fingerprint,
                      label: 'User ID',
                      value: user.id,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    _buildDetailRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    const SizedBox(height: 16),
                    // Full Name
                    _buildDetailRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: user.fullName.isNotEmpty
                          ? user.fullName
                          : 'Not set',
                    ),
                    const SizedBox(height: 16),
                    // Username
                    _buildDetailRow(
                      context,
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: user.username.isNotEmpty
                          ? user.username
                          : 'Not set',
                    ),
                    const SizedBox(height: 16),
                    // Role
                    _buildDetailRow(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Role',
                      value: user.userRole.name.toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    // Verification Status
                    _buildDetailRow(
                      context,
                      icon: user.isVerified ? Icons.verified : Icons.pending,
                      label: 'Status',
                      value: user.isVerified ? 'Verified' : 'Pending',
                      valueColor: user.isVerified
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home or dashboard
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to App',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Back to Register Button
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: Text(
                  'Back to Register',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
