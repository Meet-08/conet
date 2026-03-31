import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RewardAndOrganizerStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;

  const RewardAndOrganizerStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<RewardAndOrganizerStep> createState() => _RewardAndOrganizerStepState();
}

class _RewardAndOrganizerStepState extends State<RewardAndOrganizerStep> {
  bool _otpSent = false;
  bool _otpVerified = false;

  void _update(Map<String, dynamic> updates) {
    widget.onFormDataChange({...widget.formData, ...updates});
  }

  List<Map<String, dynamic>> get _prizes =>
      List<Map<String, dynamic>>.from(widget.formData['prizes'] as List? ?? []);

  List<Map<String, dynamic>> get _faqs =>
      List<Map<String, dynamic>>.from(widget.formData['faqs'] as List? ?? []);

  List<String> get _coOrganizers =>
      List<String>.from(widget.formData['co_organizers'] as List? ?? []);

  List<User> get _coOrganizerUsers {
    final rawUsers = List<Map<String, dynamic>>.from(
      widget.formData['co_organizer_users'] as List? ?? [],
    );

    return rawUsers
        .map(
          (raw) => User(
            id: (raw['id'] as String?) ?? '',
            email: (raw['email'] as String?) ?? '',
            firstName: (raw['first_name'] as String?) ?? '',
            lastName: (raw['last_name'] as String?) ?? '',
            username: (raw['username'] as String?) ?? '',
            profilePicUrl: raw['profile_pic_url'] as String?,
            userRole: UserRole.user,
          ),
        )
        .where((user) => user.id.isNotEmpty)
        .toList(growable: false);
  }

  void _addPrize() {
    final list = _prizes..add({'position': '', 'prize': ''});
    _update({'prizes': list});
  }

  void _removePrize(int i) {
    final list = _prizes..removeAt(i);
    _update({'prizes': list});
  }

  void _updatePrize(int i, Map<String, dynamic> patch) {
    final list = _prizes;
    list[i] = {...list[i], ...patch};
    _update({'prizes': list});
  }

  void _addFaq() {
    final list = _faqs..add({'question': '', 'answer': ''});
    _update({'faqs': list});
  }

  void _removeFaq(int i) {
    final list = _faqs..removeAt(i);
    _update({'faqs': list});
  }

  void _updateFaq(int i, Map<String, dynamic> patch) {
    final list = _faqs;
    list[i] = {...list[i], ...patch};
    _update({'faqs': list});
  }

  void _persistCoOrganizers(List<User> users) {
    final uniqueById = <String, User>{for (final user in users) user.id: user};
    final normalizedUsers = uniqueById.values.toList(growable: false);

    final usernames = normalizedUsers
        .map((user) {
          if (user.username.trim().isNotEmpty) {
            return user.username.trim();
          }
          final fullName = '${user.firstName} ${user.lastName}'.trim();
          return fullName;
        })
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    _update({
      'co_organizers': usernames,
      'co_organizer_ids': normalizedUsers
          .map((user) => user.id)
          .toList(growable: false),
      'co_organizer_users': normalizedUsers
          .map(
            (user) => {
              'id': user.id,
              'email': user.email,
              'username': user.username,
              'first_name': user.firstName,
              'last_name': user.lastName,
              'profile_pic_url': user.profilePicUrl,
            },
          )
          .toList(growable: false),
    });
  }

  void _removeCoOrganizerById(String userId) {
    final list = _coOrganizerUsers.where((user) => user.id != userId).toList();
    _persistCoOrganizers(list);
  }

  void _removeLegacyCoOrganizer(int index) {
    final list = _coOrganizers..removeAt(index);
    _update({'co_organizers': list});
  }

  Future<void> _showAddCoOrganizerSheet() async {
    final appUserState = context.read<AppUserCubit>().state;
    final currentUserId = appUserState is AppUserAuthenticated
        ? appUserState.user.id
        : null;

    final searchUsers = serviceLocator<MessageSearchUsers>();
    final selectedUsers = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Co-hosts',
      searchHint: 'Search users to add as co-host',
      emptyMessage: 'Search by name or username',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Done',
      excludedUserId: currentUserId,
      initialSelectedUsers: _coOrganizerUsers,
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (
          users,
        ) {
          return users;
        });
      },
    );

    if (selectedUsers == null) return;
    _persistCoOrganizers(selectedUsers);
  }

  // TODO: Implement actual OTP sending logic with backend
  void _sendOtp() {
    final mobileNumber = widget.formData['mobile_number'] as String? ?? '';
    if (mobileNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a mobile number first')),
      );
      return;
    }
    // TODO: Call backend to send OTP
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent (dummy)')));
  }

  // TODO: Implement actual OTP verification logic with backend
  void _showVerifyOtpDialog() {
    final otpController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify OTP'),
        content: TextField(
          controller: otpController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit OTP',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: FaIcon(FontAwesomeIcons.key, size: 15),
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
              // TODO: Call backend to verify OTP
              if (otpController.text.trim().isNotEmpty) {
                setState(() => _otpVerified = true);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP verified (dummy)')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prizes = _prizes;
    final faqs = _faqs;
    final coOrganizerUsers = _coOrganizerUsers;
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

          _SectionHeader(
            icon: FontAwesomeIcons.trophy,
            title: 'Prizes',
            actionLabel: '+ Add Prize',
            onTapAction: _addPrize,
          ),
          const SizedBox(height: 12),
          if (prizes.isEmpty)
            _EmptyBox(
              icon: FontAwesomeIcons.award,
              text: 'No prizes added yet',
              colorScheme: colorScheme,
              theme: theme,
            )
          else
            ...List.generate(prizes.length, (i) {
              final p = prizes[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: p['position'] as String? ?? '',
                          decoration: _fieldDecoration(
                            hint: '1st Place',
                            icon: FontAwesomeIcons.medal,
                          ),
                          onChanged: (v) => _updatePrize(i, {'position': v}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: p['prize'] as String? ?? '',
                          decoration: _fieldDecoration(
                            hint: 'Prize details',
                            icon: FontAwesomeIcons.gift,
                          ),
                          onChanged: (v) => _updatePrize(i, {'prize': v}),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePrize(i),
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 18),
          Text(
            'Instructions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.formData['additional_note'] as String? ?? '',
            maxLines: 4,
            decoration: _fieldDecoration(
              hint: 'What should participants know?',
              icon: FontAwesomeIcons.circleInfo,
            ),
            onChanged: (v) => _update({'additional_note': v}),
          ),

          const SizedBox(height: 22),
          const _SectionHeader(
            icon: FontAwesomeIcons.userTie,
            title: 'Organizer Contact Details',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.lgAll,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: appUser?.profilePicUrl?.isNotEmpty == true
                      ? NetworkImage(appUser!.profilePicUrl!)
                      : null,
                  child: appUser?.profilePicUrl?.isNotEmpty != true
                      ? FaIcon(
                          FontAwesomeIcons.user,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: mobileNumber,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration(
              hint: '+91 Mobile Number',
              icon: FontAwesomeIcons.phone,
            ),
            onChanged: (v) => _update({'mobile_number': v.trim()}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendOtp,
                  icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
                  label: Text(_otpVerified ? 'Verified ✓' : 'Send OTP'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              if (_otpSent && !_otpVerified) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showVerifyOtpDialog,
                    icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                    label: const Text('Verify'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 18),
          _SectionHeader(
            icon: FontAwesomeIcons.users,
            title: 'Co-Organizers',
            actionLabel: '+ Add',
            onTapAction: _showAddCoOrganizerSheet,
          ),
          const SizedBox(height: 12),
          if (coOrganizerUsers.isEmpty && coOrganizers.isEmpty)
            _EmptyBox(
              icon: FontAwesomeIcons.userGroup,
              text: 'No co-organizers added yet',
              colorScheme: colorScheme,
              theme: theme,
            )
          else if (coOrganizerUsers.isNotEmpty)
            ...coOrganizerUsers.map((cohostUser) {
              final fullName = '${cohostUser.firstName} ${cohostUser.lastName}'
                  .trim();
              final label = fullName.isNotEmpty
                  ? fullName
                  : (cohostUser.username.isNotEmpty
                        ? cohostUser.username
                        : 'Co-host');

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
                        radius: 14,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage:
                            cohostUser.profilePicUrl != null &&
                                cohostUser.profilePicUrl!.isNotEmpty
                            ? NetworkImage(cohostUser.profilePicUrl!)
                            : null,
                        child:
                            (cohostUser.profilePicUrl == null ||
                                cohostUser.profilePicUrl!.isEmpty)
                            ? FaIcon(
                                FontAwesomeIcons.user,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeCoOrganizerById(cohostUser.id),
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            })
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
                        radius: 14,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: FaIcon(
                          FontAwesomeIcons.user,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          coOrganizers[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeLegacyCoOrganizer(i),
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 18),
          _SectionHeader(
            icon: FontAwesomeIcons.circleQuestion,
            title: 'Frequently Asked Questions (FAQs)',
            actionLabel: '+ Add FAQ',
            onTapAction: _addFaq,
          ),
          const SizedBox(height: 12),
          if (faqs.isEmpty)
            _EmptyBox(
              icon: FontAwesomeIcons.solidCircleQuestion,
              text: 'No FAQs added yet',
              colorScheme: colorScheme,
              theme: theme,
            )
          else
            ...List.generate(faqs.length, (i) {
              final faq = faqs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Q${i + 1}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removeFaq(i),
                            icon: FaIcon(
                              FontAwesomeIcons.trashCan,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: faq['question'] as String? ?? '',
                        decoration: _fieldDecoration(
                          hint: 'Question',
                          icon: FontAwesomeIcons.circleQuestion,
                        ),
                        onChanged: (v) => _updateFaq(i, {'question': v}),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: faq['answer'] as String? ?? '',
                        maxLines: 3,
                        decoration: _fieldDecoration(
                          hint: 'Answer',
                          icon: FontAwesomeIcons.comment,
                        ),
                        onChanged: (v) => _updateFaq(i, {'answer': v}),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: FaIcon(icon, size: 14),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        FaIcon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onTapAction != null)
          TextButton(onPressed: onTapAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _EmptyBox({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 24, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
