import 'dart:async';

import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/common/usecases/user_search_users.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:conet_app/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

Future<List<User>?> showUserSelectorBottomSheet({
  required BuildContext context,
  List<User> initialSelectedUsers = const [],
  String title = 'Select Users',
  String searchHint = 'Search users...',
  String actionLabel = 'Done',
  String emptyMessage = 'Search by name, username, or email',
  String noResultsMessage = 'No users found',
  String? excludedUserId,
  bool allowMultipleSelection = true,
  int searchLimit = 8,
  void Function(BuildContext parentContext, User user)? onUserTap,
}) {
  return showModalBottomSheet<List<User>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UserSelectorBottomSheet(
      initialSelectedUsers: initialSelectedUsers,
      title: title,
      searchHint: searchHint,
      actionLabel: actionLabel,
      emptyMessage: emptyMessage,
      noResultsMessage: noResultsMessage,
      excludedUserId: excludedUserId,
      allowMultipleSelection: allowMultipleSelection,
      searchLimit: searchLimit,
      onUserTap: onUserTap,
      parentContext: context,
    ),
  );
}

class _UserSelectorBottomSheet extends StatefulWidget {
  final List<User> initialSelectedUsers;
  final String title;
  final String searchHint;
  final String actionLabel;
  final String emptyMessage;
  final String noResultsMessage;
  final String? excludedUserId;
  final bool allowMultipleSelection;
  final int searchLimit;
  final void Function(BuildContext parentContext, User user)? onUserTap;
  final BuildContext parentContext;

  const _UserSelectorBottomSheet({
    required this.initialSelectedUsers,
    required this.title,
    required this.searchHint,
    required this.actionLabel,
    required this.emptyMessage,
    required this.noResultsMessage,
    required this.excludedUserId,
    required this.allowMultipleSelection,
    required this.searchLimit,
    this.onUserTap,
    required this.parentContext,
  });

  @override
  State<_UserSelectorBottomSheet> createState() =>
      _UserSelectorBottomSheetState();
}

class _UserSelectorBottomSheetState extends State<_UserSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, User> _selectedUsers = {};
  final List<User> _suggestions = [];
  Timer? _debounce;
  int _searchToken = 0;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final user in widget.initialSelectedUsers) {
      if (!widget.allowMultipleSelection && _selectedUsers.isNotEmpty) {
        break;
      }
      _selectedUsers[user.id] = user;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUser(User user) {
    setState(() {
      if (_selectedUsers.containsKey(user.id)) {
        _selectedUsers.remove(user.id);
      } else if (!widget.allowMultipleSelection) {
        _selectedUsers
          ..clear()
          ..[user.id] = user;
      } else {
        _selectedUsers[user.id] = user;
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final searchUsers = serviceLocator<UserSearchUsers>();
      final result = await searchUsers(query: query, limit: widget.searchLimit);
      final users = result.fold((failure) => throw Exception(failure.message), (
        users,
      ) {
        return users;
      });
      if (!mounted || token != _searchToken) return;

      final filtered = users.where((user) {
        if (widget.excludedUserId != null && user.id == widget.excludedUserId) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _isSearching = false;
        _suggestions
          ..clear()
          ..addAll(filtered);
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _isSearching = false;
        _suggestions.clear();
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _done() {
    Navigator.of(context).pop(_selectedUsers.values.toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedUsers = _selectedUsers.values.toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.onUserTap == null)
                      TextButton(
                        onPressed: _done,
                        child: Text(
                          widget.actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onUserTap == null && selectedUsers.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: selectedUsers.map((user) {
                      final displayName = _displayName(user);
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage:
                              (user.profilePicUrl != null &&
                                  user.profilePicUrl!.isNotEmpty)
                              ? NetworkImage(user.profilePicUrl!)
                              : null,
                          child:
                              (user.profilePicUrl == null ||
                                  user.profilePicUrl!.isEmpty)
                              ? Text(
                                  _initials(user),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        label: Text(
                          displayName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        deleteIcon: const FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 12,
                        ),
                        onDeleted: () => _toggleUser(user),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (_isSearching) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    if (_error != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (_searchController.text.trim().isEmpty) {
                      return Center(
                        child: Text(
                          widget.emptyMessage,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      );
                    }

                    if (_suggestions.isEmpty) {
                      return Center(
                        child: Text(
                          widget.noResultsMessage,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final user = _suggestions[index];
                        final isSelected = _selectedUsers.containsKey(user.id);
                        return _SelectableUserTile(
                          user: user,
                          isSelected: isSelected,
                          showSelection: widget.onUserTap == null,
                          onTap: () {
                            if (widget.onUserTap != null) {
                              // Close the sheet first, then invoke the callback
                              context.pop();
                              widget.onUserTap!(widget.parentContext, user);
                            } else {
                              _toggleUser(user);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayName(User user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user.username.isNotEmpty) return user.username;
    return 'User';
  }

  String _initials(User user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) {
      return fullName
          .split(RegExp(r'\s+'))
          .map((part) => part.isNotEmpty ? part[0] : '')
          .take(2)
          .join()
          .toUpperCase();
    }
    return user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
  }
}

class _SelectableUserTile extends StatelessWidget {
  final User user;
  final bool isSelected;
  final bool showSelection;
  final VoidCallback onTap;

  const _SelectableUserTile({
    required this.user,
    required this.isSelected,
    required this.showSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = '${user.firstName} ${user.lastName}'.trim();
    final username = user.username.trim();
    final subtitle = username;
    final initials = _initials(displayName, user.username);

    logger.d(
      'Building user tile for ${user.id} - $displayName ($subtitle), selected: $isSelected username: ${user.username}, email: ${user.email}',
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty)
            ? NetworkImage(user.profilePicUrl!)
            : null,
        child: (user.profilePicUrl == null || user.profilePicUrl!.isEmpty)
            ? Text(initials)
            : null,
      ),
      title: Text(
        displayName.isNotEmpty
            ? displayName
            : (username.isNotEmpty ? username : 'User'),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: showSelection
          ? (isSelected
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.primary,
                    child: const FaIcon(
                      FontAwesomeIcons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                : CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                  ))
          : null,
      onTap: onTap,
    );
  }

  String _initials(String displayName, String username) {
    if (displayName.isNotEmpty) {
      return displayName
          .split(RegExp(r'\s+'))
          .map((part) => part.isNotEmpty ? part[0] : '')
          .take(2)
          .join()
          .toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }
}
