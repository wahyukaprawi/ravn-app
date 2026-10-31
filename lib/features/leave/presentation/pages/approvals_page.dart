import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_format.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/models/leave_models.dart';
import '../cubit/leave_cubit.dart';
import 'leave_detail_page.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  bool _processing = false;
  int? _processingRequestId;
  int? _processingCancellationId;

  Future<void> _decide(LeaveRequestModel request, String action) async {
    if (_processing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          action == 'approve' ? 'Approve request?' : 'Reject request?',
        ),
        content: Text(
          '${request.employee.name} · ${request.leaveType?.name ?? 'Leave'}\n'
          '${request.startDate} to ${request.endDate} (${formatWholeNumber(request.days)} day(s))',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: action == 'reject'
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processing = true;
      _processingRequestId = request.id;
    });

    final cubit = context.read<LeaveCubit>();
    await cubit.decideApproval(request.id, action);

    if (!mounted) return;

    setState(() {
      _processing = false;
      _processingRequestId = null;
    });

    _reportResult(
      cubit.state,
      action == 'approve' ? 'Request approved.' : 'Request rejected.',
    );
  }

  Future<void> _decideCancellation(
    LeaveCancellationModel cancellation,
    String action,
  ) async {
    if (_processing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          action == 'approve'
              ? 'Approve cancellation?'
              : 'Reject cancellation?',
        ),
        content: Text(
          '${cancellation.requester.name} · leave request #${cancellation.leaveRequestId}\n'
          'Reason: ${cancellation.reason}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: action == 'reject'
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processing = true;
      _processingCancellationId = cancellation.id;
    });

    final cubit = context.read<LeaveCubit>();
    await cubit.decideCancellation(cancellation.id, action);

    if (!mounted) return;

    setState(() {
      _processing = false;
      _processingCancellationId = null;
    });

    _reportResult(
      cubit.state,
      action == 'approve' ? 'Cancellation approved.' : 'Cancellation rejected.',
    );
  }

  void _reportResult(LeaveState state, String successMessage) {
    final isError = state is LeaveError;
    final message = state is LeaveError ? state.message : successMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approval Inbox'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _processing
                  ? null
                  : () => context.read<LeaveCubit>().loadLeaveData(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Leave'),
              Tab(text: 'Cancellations'),
            ],
          ),
        ),
        body: BlocBuilder<LeaveCubit, LeaveState>(
          builder: (context, state) {
            if (state is LeaveLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LeaveError) {
              return _ErrorState(
                message: state.message,
                onRetry: () => context.read<LeaveCubit>().loadLeaveData(),
              );
            }

            if (state is! LeaveLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                if (_processing) const LinearProgressIndicator(minHeight: 4),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildApprovalList(state.approvals),
                      _buildCancellationList(state.cancellations),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildApprovalList(List<LeaveRequestModel> approvals) {
    if (approvals.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        message: 'No pending leave approvals',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approvals.length,
      itemBuilder: (context, index) {
        final request = approvals[index];
        final isProcessingRequest = _processingRequestId == request.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.employee.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.employee.email,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: request.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  request.leaveType?.name ?? 'Leave',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.startDate} to ${request.endDate}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                Text(
                  '${formatWholeNumber(request.days)} day(s)',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    request.reason!,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                if (isProcessingRequest)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing
                              ? null
                              : () => _decide(request, 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processing
                              ? null
                              : () => _decide(request, 'approve'),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaveDetailPage(request: request),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCancellationList(List<LeaveCancellationModel> cancellations) {
    if (cancellations.isEmpty) {
      return const _EmptyState(
        icon: Icons.cancel_outlined,
        message: 'No pending cancellation requests',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cancellations.length,
      itemBuilder: (context, index) {
        final cancellation = cancellations[index];
        final isProcessingCancellation =
            _processingCancellationId == cancellation.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cancellation.requester.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusChip(status: cancellation.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave request #${cancellation.leaveRequestId}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  cancellation.reason,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                if (isProcessingCancellation)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing
                              ? null
                              : () =>
                                    _decideCancellation(cancellation, 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processing
                              ? null
                              : () => _decideCancellation(
                                  cancellation,
                                  'approve',
                                ),
                          child: const Text('Approve'),
                        ),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
