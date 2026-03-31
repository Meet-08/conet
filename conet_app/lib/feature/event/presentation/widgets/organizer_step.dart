import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OrganizerStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;

  const OrganizerStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<OrganizerStep> createState() => _OrganizerStepState();
}

class _OrganizerStepState extends State<OrganizerStep> {
  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  List<String> get _coOrganizers =>
      List<String>.from(widget.formData['co_organizers'] as List? ?? []);

  void _addCoOrganizer(String username) {
    if (username.trim().isEmpty) return;
    final list = _coOrganizers..add(username.trim());
    _update({'co_organizers': list});
  }

  void _removeCoOrganizer(int i) {
    final list = _coOrganizers..removeAt(i);
    _update({'co_organizers': list});
  }

  void _showAddCoOrganizerDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Co-organizer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '@username',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: FaIcon(FontAwesomeIcons.at, size: 15),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _addCoOrganizer(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coOrganizers = _coOrganizers;
    final mobileNumber = widget.formData['mobile_number'] as String? ?? '';

    final appUserState = context.read<AppUserCubit>().state;
    final appUser = appUserState is AppUserAuthenticated
        ? appUserState.user
        : null;
    final fullName = appUser != null
        ? '${appUser.firstName} ${appUser.lastName}'.trim()
        : '';
    final displayName = fullName.isNotEmpty
        ? fullName
        : (appUser?.username ?? 'Unknown');
    final displayHandle = appUser?.username.isNotEmpty == true
        ? '@${appUser!.username}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step Header ──
          Text(
            widget.stepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // ── Organizer profile card ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.lgAll,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: appUser?.profilePicUrl?.isNotEmpty == true
                      ? NetworkImage(appUser!.profilePicUrl!)
                      : null,
                  child: appUser?.profilePicUrl?.isNotEmpty != true
                      ? FaIcon(
                          FontAwesomeIcons.user,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (displayHandle != null)
                      Text(
                        displayHandle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Mobile number ──
          if (mobileNumber.isEmpty)
            GestureDetector(
              onTap: _showMobileDialog,
              child: Text(
                'Add mobile number',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.phone,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(mobileNumber, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showMobileDialog,
                  child: Text(
                    'Edit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 28),

          // ── Co-organizers ──
          Row(
            children: [
              Text(
                'Add Co-organizers',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showAddCoOrganizerDialog,
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.userPlus,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (coOrganizers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No co-organizers added yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...List.generate(coOrganizers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          coOrganizers[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        onPressed: () => _removeCoOrganizer(i),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showMobileDialog() {
    final controller = TextEditingController(
      text: widget.formData['mobile_number'] as String? ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mobile Number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+91 00000 00000',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: FaIcon(FontAwesomeIcons.phone, size: 15),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _update({'mobile_number': controller.text.trim()});
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
