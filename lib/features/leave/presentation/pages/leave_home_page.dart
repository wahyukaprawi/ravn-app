import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../cubit/leave_cubit.dart';
import 'leave_submit_page.dart';
import 'leave_detail_page.dart';
import 'approvals_page.dart';

class LeaveHomePage extends StatefulWidget {
  const LeaveHomePage({super.key});

  @override
  State<LeaveHomePage> createState() => _LeaveHomePageState();
}

class _LeaveHomePageState extends State<LeaveHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<LeaveCubit>().loadLeaveData();
    context.read<NotificationCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'attendance':
        await context.push('/attendance');
        return;
      case 'approvals':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApprovalsPage()),
        );
        return;
      case 'directory':
        await context.push('/directory');
        return;
      case 'profile':
        final auth = context.read<AuthCubit>().state;
        if (auth is AuthAuthenticated && auth.user.employeeId != null) {
          await context.push('/directory/${auth.user.employeeId}');
        }
        return;
      case 'notificationSettings':
        await context.push('/notification-settings');
        return;
      case 'refresh':
        await context.read<LeaveCubit>().loadLeaveData();
        return;
      case 'signOut':
        await _confirmSignOut();
        return;
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your session token will be revoked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        actions: [
          IconButton(
            icon: const Icon(HeroiconsOutline.megaphone),
            tooltip: 'Announcements',
            onPressed: () => context.push('/announcements'),
          ),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final unread = state is NotificationLoaded
                  ? state.unreadCount
                  : 0;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(HeroiconsOutline.bell),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              _handleMenuAction(value);
            },
            itemBuilder: (context) {
              final auth = context.read<AuthCubit>().state;
              final user = auth is AuthAuthenticated ? auth.user : null;
              final canViewDirectory =
                  user?.permissions.contains('employees.view_any') ?? false;
              final canApprove =
                  user?.permissions.contains('workflow.approve') ?? false;

              return [
                const PopupMenuItem(
                  value: 'attendance',
                  child: Row(
                    children: [
                      Icon(HeroiconsOutline.clock),
                      SizedBox(width: 12),
                      Text('Attendance'),
                    ],
                  ),
                ),
                if (canApprove)
                  const PopupMenuItem(
                    value: 'approvals',
                    child: Row(
                      children: [
                        Icon(HeroiconsOutline.inbox),
                        SizedBox(width: 12),
                        Text('Approvals'),
                      ],
                    ),
                  ),
                if (canViewDirectory)
                  const PopupMenuItem(
                    value: 'directory',
                    child: Row(
                      children: [
                        Icon(HeroiconsOutline.users),
                        SizedBox(width: 12),
                        Text('People directory'),
                      ],
                    ),
                  ),
                if (user?.employeeId != null)
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(HeroiconsOutline.userCircle),
                        SizedBox(width: 12),
                        Text('My profile'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'notificationSettings',
                  child: Row(
                    children: [
                      Icon(HeroiconsOutline.bellAlert),
                      SizedBox(width: 12),
                      Text('Notification settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'signOut',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryStrong,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Balances'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: BlocBuilder<LeaveCubit, LeaveState>(
        builder: (context, state) {
          if (state is LeaveLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LeaveError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    HeroiconsOutline.exclamationTriangle,
                    size: 48,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<LeaveCubit>().loadLeaveData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is LeaveLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(state),
                _buildBalancesTab(state),
                _buildHistoryTab(state),
              ],
            );
          }
          return const Center(child: Text('No data'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveSubmitPage()),
          );
          if (!context.mounted) return;
          context.read<LeaveCubit>().loadLeaveData();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        icon: const Icon(HeroiconsOutline.plus),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildRequestsTab(LeaveLoaded state) {
    final activeRequests = state.requests
        .where((r) => r.status == 'pending' || r.status == 'held')
        .toList();

    if (activeRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              HeroiconsOutline.calendarDays,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No active requests',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        final request = activeRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  request.leaveType?.name ?? 'Leave',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                StatusChip(status: request.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${request.startDate} to ${request.endDate} • ${request.days} day(s)',
                ),
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.reason!,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveDetailPage(request: request),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab(LeaveLoaded state) {
    if (state.balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              HeroiconsOutline.documentText,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No balance information',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.balances.length,
      itemBuilder: (context, index) {
        final balance = state.balances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.leaveType.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBalanceColumn('Entitled', balance.entitled),
                    _buildBalanceColumn('Used', balance.used),
                    _buildBalanceColumn('Reserved', balance.reserved),
                    _buildBalanceColumn(
                      'Available',
                      balance.available,
                      isAvailable: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceColumn(
    String label,
    double value, {
    bool isAvailable = false,
  }) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isAvailable ? AppColors.success : AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildHistoryTab(LeaveLoaded state) {
    final historyRequests = state.requests
        .where(
          (r) =>
              r.status == 'approved' ||
              r.status == 'rejected' ||
              r.status == 'canceled',
        )
        .toList();

    if (historyRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              HeroiconsOutline.inbox,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('No history', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyRequests.length,
      itemBuilder: (context, index) {
        final request = historyRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  request.leaveType?.name ?? 'Leave',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                StatusChip(status: request.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${request.startDate} to ${request.endDate} • ${request.days} day(s)',
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveDetailPage(request: request),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
