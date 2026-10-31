import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_format.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/leave_models.dart';
import '../cubit/leave_cubit.dart';

class LeaveDetailPage extends StatelessWidget {
  final LeaveRequestModel request;

  const LeaveDetailPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          request.leaveType?.name ?? 'Leave',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StatusChip(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRow('Start Date', request.startDate),
                    _buildRow('End Date', request.endDate),
                    _buildRow('Days', formatWholeNumber(request.days)),
                    if (request.manager != null)
                      _buildRow('Manager', request.manager!.name),
                    if (request.reason != null &&
                        request.reason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(request.reason!),
                    ],
                  ],
                ),
              ),
            ),
            if (request.workflow != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approval Workflow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...request.workflow!.steps.map((step) {
                        final isCompleted =
                            step.status == 'approved' ||
                            step.status == 'rejected';
                        final isCurrent =
                            step.status == 'active' || step.status == 'pending';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? AppColors.success
                                          : isCurrent
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      border: Border.all(
                                        color: isCompleted || isCurrent
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                    child: Icon(
                                      isCompleted && step.action == 'approve'
                                          ? Icons.check
                                          : isCompleted &&
                                                step.action == 'reject'
                                          ? Icons.close
                                          : Icons.circle,
                                      color: isCompleted || isCurrent
                                          ? AppColors.background
                                          : AppColors.textMuted,
                                      size: 18,
                                    ),
                                  ),
                                  if (step.position <
                                      request.workflow!.steps.length)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      color: AppColors.primaryContainer,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.key == 'manager'
                                          ? 'Manager Approval'
                                          : 'HR Admin Approval',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step.assigneeName ??
                                          (step.assigneeType == 'role'
                                              ? step.key
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase()
                                              : 'Unassigned'),
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (step.status == 'approved' &&
                                        step.action == 'approve')
                                      const Text(
                                        'Approved',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                        ),
                                      )
                                    else if (step.status == 'rejected')
                                      const Text(
                                        'Rejected',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 12,
                                        ),
                                      )
                                    else if (isCurrent)
                                      const Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            if (request.status == 'pending' ||
                request.status == 'held' ||
                _isApprovedNotStarted(request)) ...[
              const SizedBox(height: 16),
              _CancelAction(request: request),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool _isApprovedNotStarted(LeaveRequestModel request) {
    if (request.status != 'approved') return false;

    final start = DateTime.tryParse(request.startDate);
    if (start == null) return false;

    final today = DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return startDay.isAfter(todayDay);
  }
}

class _CancelAction extends StatefulWidget {
  const _CancelAction({required this.request});

  final LeaveRequestModel request;

  @override
  State<_CancelAction> createState() => _CancelActionState();
}

class _CancelActionState extends State<_CancelAction> {
  bool _submitting = false;

  Future<void> _cancel() async {
    if (_submitting) return;

    final reason = await _askReason();
    if (reason == null || !mounted) return;

    setState(() => _submitting = true);
    final cubit = context.read<LeaveCubit>();
    final needsApproval = await cubit.cancelRequest(widget.request.id, reason);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (needsApproval == null) {
      final state = cubit.state;
      final message = state is LeaveError
          ? state.message
          : 'Cancellation failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsApproval
              ? 'Cancellation request submitted for approval.'
              : 'Leave request canceled.',
        ),
        backgroundColor: needsApproval ? AppColors.warning : AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  Future<String?> _askReason() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          widget.request.status == 'approved'
              ? 'Request Leave Cancellation'
              : 'Cancel Leave Request',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Enter reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    reasonController.dispose();
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.request.status == 'approved';

    return AppButton(
      text: isApproved ? 'Request Cancellation' : 'Cancel Request',
      isOutlined: true,
      isLoading: _submitting,
      onPressed: _submitting ? null : _cancel,
    );
  }
}
