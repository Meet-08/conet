import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RewardAndOrganizerStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final ValueChanged<Map<String, dynamic>> onFormDataChange;
  final String stepTitle;
  final String stepSubtitle;
  final bool lockToggles;

  const RewardAndOrganizerStep({
    super.key,
    required this.formData,
    required this.onFormDataChange,
    required this.stepTitle,
    required this.stepSubtitle,
    this.lockToggles = false,
  });

  @override
  State<RewardAndOrganizerStep> createState() => _RewardAndOrganizerStepState();
}

class _RewardAndOrganizerStepState extends State<RewardAndOrganizerStep> {
  final TextEditingController _prizeRankController = TextEditingController();
  final TextEditingController _prizeRewardController = TextEditingController();
  final TextEditingController _faqQuestionController = TextEditingController();
  final TextEditingController _faqAnswerController = TextEditingController();

  int? _editingPrizeIndex;
  int? _editingFaqIndex;
  bool _showPrizeEditor = false;
  bool _showFaqEditor = false;

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

  void _addPrize() => _startPrizeEditor();

  void _removePrize(int i) {
    final list = _prizes..removeAt(i);
    _update({'prizes': list});
    if (_editingPrizeIndex == i) {
      _cancelPrizeEditor();
    }
  }

  void _startPrizeEditor({int? index}) {
    final prize = index == null ? <String, dynamic>{} : _prizes[index];
    _editingPrizeIndex = index;
    _prizeRankController.text = (prize['position'] as String?) ?? '';
    _prizeRewardController.text = (prize['prize'] as String?) ?? '';
    setState(() => _showPrizeEditor = true);
  }

  void _cancelPrizeEditor() {
    _editingPrizeIndex = null;
    _prizeRankController.clear();
    _prizeRewardController.clear();
    setState(() => _showPrizeEditor = false);
  }

  void _savePrizeEditor() {
    final rank = _prizeRankController.text.trim();
    final reward = _prizeRewardController.text.trim();
    if (rank.isEmpty || reward.isEmpty) {
      AppToast.showWarning(context, 'Rank and reward are required');
      return;
    }

    final list = _prizes;
    final item = <String, dynamic>{'position': rank, 'prize': reward};

    if (_editingPrizeIndex != null) {
      list[_editingPrizeIndex!] = item;
    } else {
      list.add(item);
    }

    _update({'prizes': list});
    _cancelPrizeEditor();
  }

  void _addFaq() => _startFaqEditor();

  void _removeFaq(int i) {
    final list = _faqs..removeAt(i);
    _update({'faqs': list});
    if (_editingFaqIndex == i) {
      _cancelFaqEditor();
    }
  }

  void _startFaqEditor({int? index}) {
    final faq = index == null ? <String, dynamic>{} : _faqs[index];
    _editingFaqIndex = index;
    _faqQuestionController.text = (faq['question'] as String?) ?? '';
    _faqAnswerController.text = (faq['answer'] as String?) ?? '';
    setState(() => _showFaqEditor = true);
  }

  void _cancelFaqEditor() {
    _editingFaqIndex = null;
    _faqQuestionController.clear();
    _faqAnswerController.clear();
    setState(() => _showFaqEditor = false);
  }

  void _saveFaqEditor() {
    final question = _faqQuestionController.text.trim();
    final answer = _faqAnswerController.text.trim();
    if (question.isEmpty || answer.isEmpty) {
      AppToast.showWarning(context, 'Question and answer are required');
      return;
    }

    final list = _faqs;
    final item = <String, dynamic>{'question': question, 'answer': answer};

    if (_editingFaqIndex != null) {
      list[_editingFaqIndex!] = item;
    } else {
      list.add(item);
    }

    _update({'faqs': list});
    _cancelFaqEditor();
  }

  Future<void> _showAddCoOrganizerSheet() async {
    final appUserState = context.read<AppUserCubit>().state;
    final currentUserId = appUserState is AppUserAuthenticated
        ? appUserState.user.id
        : null;

    final selectedUsers = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Co-hosts',
      searchHint: 'Search users to add as co-host',
      emptyMessage: 'Search by name, username, or email',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Done',
      excludedUserId: currentUserId,
      initialSelectedUsers: _coOrganizerUsers,
    );

    if (selectedUsers == null) return;

    final uniqueById = <String, User>{
      for (final user in selectedUsers) user.id: user,
    };
    final normalizedUsers = uniqueById.values.toList(growable: false);
    final usernames = normalizedUsers
        .map(
          (user) => user.username.trim().isNotEmpty
              ? user.username.trim()
              : '${user.firstName} ${user.lastName}'.trim(),
        )
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
      'event_conversation_id': null,
    });
  }

  void _sendOtp() {
    final mobileNumber = widget.formData['mobile_number'] as String? ?? '';
    if (mobileNumber.trim().isEmpty) {
      AppToast.showWarning(context, 'Please enter a mobile number first');
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent (dummy)')));
  }

  void _toggleConversation(bool value) {
    _update({
      'create_event_conversation': value,
      if (!value) 'event_conversation_id': null,
    });
  }

  String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'EV';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      final part = parts.first;
      return part.length == 1
          ? part.toUpperCase()
          : part.substring(0, 2).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  void dispose() {
    _prizeRankController.dispose();
    _prizeRewardController.dispose();
    _faqQuestionController.dispose();
    _faqAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final prizes = _prizes;
    final faqs = _faqs;
    final coOrganizerUsers = _coOrganizerUsers;
    final coOrganizers = _coOrganizers;
    final mobileNumber = widget.formData['mobile_number'] as String? ?? '';
    final createEventConversation =
        widget.formData['create_event_conversation'] as bool? ?? false;
    final currentUserState = context.read<AppUserCubit>().state;
    final currentUser = currentUserState is AppUserAuthenticated
        ? currentUserState.user
        : null;
    final fullName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
        : '';
    final displayName = fullName.isNotEmpty
        ? fullName
        : (currentUser?.username.isNotEmpty == true
              ? currentUser!.username
              : 'Organizer');
    final displayHandle = currentUser?.username.isNotEmpty == true
        ? '@${currentUser!.username}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s24,
        AppSpace.s16,
        AppSpace.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.stepTitle,
            style: AppTextStyles.headingH2.copyWith(
              fontWeight: FontWeight.w800,
              color: semantic.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            widget.stepSubtitle,
            style: AppTextStyles.bodyDefault.copyWith(
              color: semantic.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.s24),

          const _SectionTitle(icon: FontAwesomeIcons.gift, title: 'Prizes'),
          const SizedBox(height: AppSpace.s16),
          if (prizes.isNotEmpty)
            ...List.generate(prizes.length, (index) {
              final prize = prizes[index];
              final rank = (prize['position'] as String? ?? '').trim();
              final reward = (prize['prize'] as String? ?? '').trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s12),
                child: _PrizeCard(
                  semantic: semantic,
                  rank: rank.isEmpty ? 'Prize ${index + 1}' : rank,
                  reward: reward.isEmpty ? 'Prize details' : reward,
                  onTap: () => _startPrizeEditor(index: index),
                  onDelete: () => _removePrize(index),
                ),
              );
            }),
          if (_showPrizeEditor) ...[
            _PrizeEditorCard(
              semantic: semantic,
              rankController: _prizeRankController,
              rewardController: _prizeRewardController,
              isEditing: _editingPrizeIndex != null,
              onCancel: _cancelPrizeEditor,
              onSave: _savePrizeEditor,
            ),
            const SizedBox(height: AppSpace.s12),
          ],
          _AddFieldButton(
            semantic: semantic,
            label: 'Add Prizes',
            onTap: _addPrize,
          ),

          const SizedBox(height: AppSpace.s24),
          const _SectionTitle(
            icon: FontAwesomeIcons.circleInfo,
            title: 'Instructions',
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'What should participants know?',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            initialValue: widget.formData['additional_note'] as String? ?? '',
            maxLines: 4,
            maxLength: 300,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => const SizedBox.shrink(),
            decoration: _inputDecoration(
              context,
              hint: 'e.g., Bring your laptop, chargers, and a valid ID card.',
            ),
            onChanged: (value) => _update({'additional_note': value}),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${(widget.formData['additional_note'] as String? ?? '').length}/300 characters used',
              style: AppTextStyles.caption.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: AppSpace.s24),
          const _SectionTitle(
            icon: FontAwesomeIcons.userTie,
            title: 'Organizer Contact Info',
          ),
          const SizedBox(height: AppSpace.s12),
          _OrganizerProfileCard(
            semantic: semantic,
            displayName: displayName,
            displayHandle: displayHandle,
            profilePicUrl: currentUser?.profilePicUrl,
            initials: _initials(displayName),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Mobile Number',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            initialValue: mobileNumber,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              context,
              hint: '+91 1234567890',
              prefixIcon: FontAwesomeIcons.phone,
            ),
            onChanged: (value) => _update({'mobile_number': value.trim()}),
          ),
          const SizedBox(height: AppSpace.s8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _sendOtp,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
              ),
              child: const Text('Send OTP'),
            ),
          ),

          const SizedBox(height: AppSpace.s24),
          _SectionTitle(
            icon: FontAwesomeIcons.users,
            title: 'Co-Organizers',
            actionLabel: '+ Add Co-organizer',
            onTapAction: _showAddCoOrganizerSheet,
          ),
          const SizedBox(height: AppSpace.s12),
          if (coOrganizerUsers.isEmpty && coOrganizers.isEmpty)
            _EmptyStateCard(
              semantic: semantic,
              icon: FontAwesomeIcons.userGroup,
              text: 'No co-organizers added yet',
            )
          else if (coOrganizerUsers.isNotEmpty)
            ...List.generate(coOrganizerUsers.length, (index) {
              final cohostUser = coOrganizerUsers[index];
              final fullName = '${cohostUser.firstName} ${cohostUser.lastName}'
                  .trim();
              final label = fullName.isNotEmpty
                  ? fullName
                  : (cohostUser.username.isNotEmpty
                        ? cohostUser.username
                        : 'Co-host');

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s10),
                child: _UserEntryCard(
                  semantic: semantic,
                  name: label,
                  handle: cohostUser.username.isNotEmpty
                      ? '@${cohostUser.username}'
                      : null,
                  profilePicUrl: cohostUser.profilePicUrl,
                  initials: _initials(label),
                  onRemove: () {
                    final remaining = coOrganizerUsers
                        .where((user) => user.id != cohostUser.id)
                        .toList(growable: false);
                    final usernames = remaining
                        .map(
                          (user) => user.username.trim().isNotEmpty
                              ? user.username.trim()
                              : '${user.firstName} ${user.lastName}'.trim(),
                        )
                        .where((value) => value.isNotEmpty)
                        .toList(growable: false);
                    _update({
                      'co_organizers': usernames,
                      'co_organizer_ids': remaining
                          .map((user) => user.id)
                          .toList(growable: false),
                      'co_organizer_users': remaining
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
                  },
                ),
              );
            })
          else
            ...List.generate(coOrganizers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s10),
                child: _UserEntryCard(
                  semantic: semantic,
                  name: coOrganizers[index],
                  handle: null,
                  profilePicUrl: null,
                  initials: _initials(coOrganizers[index]),
                  onRemove: () {
                    final remaining = _coOrganizers..removeAt(index);
                    _update({'co_organizers': remaining});
                  },
                ),
              );
            }),
          const SizedBox(height: AppSpace.s8),
          _AddFieldButton(
            semantic: semantic,
            label: 'Add Co-organizer',
            onTap: _showAddCoOrganizerSheet,
          ),

          const SizedBox(height: AppSpace.s24),
          const _SectionTitle(
            icon: FontAwesomeIcons.comments,
            title: 'Discussion',
          ),
          const SizedBox(height: AppSpace.s12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              color: semantic.surfaceRaised,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: semantic.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: semantic.surfaceOverlay,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    FontAwesomeIcons.message,
                    size: 16,
                    color: semantic.iconPrimary,
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Group Chat',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: semantic.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-create a group chat that auto-adds participants upon registration.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: semantic.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: createEventConversation,
                  onChanged: widget.lockToggles ? null : _toggleConversation,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.s24),
          const _SectionTitle(
            icon: FontAwesomeIcons.circleQuestion,
            title: 'Frequently Asked Questions (FAQs)',
            actionLabel: null,
          ),
          const SizedBox(height: AppSpace.s12),
          if (faqs.isEmpty)
            _EmptyStateCard(
              semantic: semantic,
              icon: FontAwesomeIcons.solidCircleQuestion,
              text: 'No FAQs added yet',
            )
          else
            ...List.generate(faqs.length, (index) {
              final faq = faqs[index];
              final question = (faq['question'] as String? ?? '').trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s10),
                child: _FaqChipCard(
                  semantic: semantic,
                  question: question.isEmpty ? 'FAQ ${index + 1}' : question,
                  onTap: () => _startFaqEditor(index: index),
                  onRemove: () => _removeFaq(index),
                ),
              );
            }),
          if (_showFaqEditor) ...[
            _FaqEditorCard(
              semantic: semantic,
              questionController: _faqQuestionController,
              answerController: _faqAnswerController,
              isEditing: _editingFaqIndex != null,
              onCancel: _cancelFaqEditor,
              onSave: _saveFaqEditor,
            ),
            const SizedBox(height: AppSpace.s12),
          ],
          _AddFieldButton(semantic: semantic, label: 'Add FAQ', onTap: _addFaq),
          const SizedBox(height: AppSpace.s16),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    IconData? prefixIcon,
  }) {
    final semantic = context.semanticColors;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: semantic.surfaceBase,
      isDense: true,
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: FaIcon(prefixIcon, size: 14, color: semantic.iconTertiary),
            ),
      prefixIconConstraints: prefixIcon == null
          ? null
          : const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Row(
      children: [
        FaIcon(icon, size: 16, color: semantic.iconPrimary),
        const SizedBox(width: AppSpace.s10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingH3.copyWith(
              fontWeight: FontWeight.w800,
              color: semantic.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onTapAction != null)
          TextButton(onPressed: onTapAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final String rank;
  final String reward;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PrizeCard({
    required this.semantic,
    required this.rank,
    required this.reward,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: semantic.surfaceRaised,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: semantic.backgroundSecondary,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  FontAwesomeIcons.medal,
                  size: 15,
                  color: semantic.iconBrand,
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: semantic.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reward,
                      style: AppTextStyles.bodyDefault.copyWith(
                        color: semantic.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: semantic.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrizeEditorCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final TextEditingController rankController;
  final TextEditingController rewardController;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _PrizeEditorCard({
    required this.semantic,
    required this.rankController,
    required this.rewardController,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpace.s12),
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: semantic.surfaceOverlay,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  FontAwesomeIcons.award,
                  size: 15,
                  color: semantic.iconPrimary,
                ),
              ),
              const SizedBox(width: AppSpace.s10),
              Text(
                'Prize',
                style: AppTextStyles.headingH3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: semantic.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Rank',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            controller: rankController,
            decoration: _sharedInputDecoration(
              context,
              semantic: semantic,
              hint: 'e.g. 2nd place',
              icon: FontAwesomeIcons.medal,
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Rewards',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            controller: rewardController,
            decoration: _sharedInputDecoration(
              context,
              semantic: semantic,
              hint: '₹5,000 Cash + Certificate',
              icon: FontAwesomeIcons.gift,
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _sharedInputDecoration(
    BuildContext context, {
    required AppSemanticColors semantic,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: semantic.surfaceBase,
      isDense: true,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: FaIcon(icon, size: 14, color: semantic.iconTertiary),
            ),
      prefixIconConstraints: icon == null
          ? null
          : const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
      ),
    );
  }
}

class _FaqEditorCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final TextEditingController questionController;
  final TextEditingController answerController;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _FaqEditorCard({
    required this.semantic,
    required this.questionController,
    required this.answerController,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.circleQuestion,
                size: 16,
                color: semantic.iconPrimary,
              ),
              const SizedBox(width: AppSpace.s8),
              Text(
                'FAQ',
                style: AppTextStyles.headingH3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: semantic.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Question',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            controller: questionController,
            decoration: _faqDecoration(
              semantic: semantic,
              hint: 'e.g. Do I need to bring my own tools?',
              icon: FontAwesomeIcons.circleQuestion,
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Answer',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          TextFormField(
            controller: answerController,
            maxLines: 4,
            minLines: 3,
            decoration: _faqDecoration(
              semantic: semantic,
              hint:
                  'No, you do not have to bring anything. We will provide everything needed.',
              icon: FontAwesomeIcons.commentDots,
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _faqDecoration({
    required AppSemanticColors semantic,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: semantic.surfaceBase,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: FaIcon(icon, size: 14, color: semantic.iconTertiary),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
      ),
    );
  }
}

class _OrganizerProfileCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final String displayName;
  final String? displayHandle;
  final String? profilePicUrl;
  final String initials;

  const _OrganizerProfileCard({
    required this.semantic,
    required this.displayName,
    required this.displayHandle,
    required this.profilePicUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: semantic.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: semantic.surfaceOverlay,
            backgroundImage: profilePicUrl?.isNotEmpty == true
                ? NetworkImage(profilePicUrl!)
                : null,
            child: profilePicUrl?.isNotEmpty == true
                ? null
                : Text(
                    initials,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: semantic.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: semantic.textPrimary,
                  ),
                ),
                if (displayHandle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayHandle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: semantic.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserEntryCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final String name;
  final String? handle;
  final String? profilePicUrl;
  final String initials;
  final VoidCallback onRemove;

  const _UserEntryCard({
    required this.semantic,
    required this.name,
    required this.handle,
    required this.profilePicUrl,
    required this.initials,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: semantic.surfaceOverlay,
            backgroundImage: profilePicUrl?.isNotEmpty == true
                ? NetworkImage(profilePicUrl!)
                : null,
            child: profilePicUrl?.isNotEmpty == true
                ? null
                : Text(
                    initials,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: semantic.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpace.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: semantic.textPrimary,
                  ),
                ),
                if (handle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    handle!,
                    style: AppTextStyles.caption.copyWith(
                      color: semantic.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: FaIcon(
              FontAwesomeIcons.xmark,
              size: 15,
              color: semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqChipCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final String question;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FaqChipCard({
    required this.semantic,
    required this.question,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: semantic.surfaceRaised,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s12,
            vertical: AppSpace.s10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: AppTextStyles.bodyDefault.copyWith(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 15,
                  color: semantic.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final AppSemanticColors semantic;
  final String label;
  final VoidCallback onTap;

  const _AddFieldButton({
    required this.semantic,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: AppRadius.md,
        dashPattern: const [6, 4],
        strokeWidth: 1.2,
        color: semantic.borderDefault,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.plus,
                size: 14,
                color: semantic.textPrimary,
              ),
              const SizedBox(width: AppSpace.s8),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: semantic.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final IconData icon;
  final String text;

  const _EmptyStateCard({
    required this.semantic,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpace.s12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s12,
        vertical: AppSpace.s16,
      ),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 22, color: semantic.iconTertiary),
          const SizedBox(height: AppSpace.s8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: semantic.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
