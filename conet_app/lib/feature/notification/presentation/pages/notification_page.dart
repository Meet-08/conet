import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:conet_app/feature/notification/presentation/widgets/notification_empty_state.dart';
import 'package:conet_app/feature/notification/presentation/widgets/notification_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const NotificationLoadEvent());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<NotificationBloc>().add(const NotificationLoadMoreEvent());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= maxScroll - 200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          BlocSelector<NotificationBloc, NotificationState, int>(
            selector: (state) => state.unseenCount,
            builder: (context, unseenCount) {
              if (unseenCount <= 0) return const SizedBox.shrink();
              return IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.checkDouble,
                  size: 18,
                  color: Colors.black54,
                ),
                tooltip: 'Mark all as read',
                onPressed: () {
                  context.read<NotificationBloc>().add(
                    const NotificationMarkAllSeenEvent(),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.error != null) {
            AppToast.showError(context, state.error!.message);
          }
        },
        builder: (context, state) {
          // Initial loading
          if (state.isLoading && state.notifications.isEmpty) {
            return const Center(child: Loader());
          }

          // Empty state
          if (!state.isLoading && state.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: NotificationEmptyState(),
                  ),
                ],
              ),
            );
          }

          // Notifications list
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount:
                  state.notifications.length + (state.isFetchingMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                // Loading indicator at the end
                if (index >= state.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Loader(size: 20)),
                  );
                }

                return NotificationListItem(
                  notification: state.notifications[index],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    context.read<NotificationBloc>().add(const NotificationLoadEvent());
  }
}
