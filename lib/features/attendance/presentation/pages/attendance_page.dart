import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/attendance_models.dart';
import '../cubit/attendance_cubit.dart';
import 'face_liveness_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<AttendanceCubit>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Leave',
            onPressed: () => context.push('/home'),
          ),
        ],
      ),
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listenWhen: (previous, current) {
          return current is AttendanceLoaded && current.notice != null;
        },
        listener: (context, state) {
          if (state is! AttendanceLoaded || state.notice == null) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              backgroundColor: state.noticeIsError
                  ? AppColors.danger
                  : AppColors.success,
            ),
          );
          context.read<AttendanceCubit>().clearNotice();
        },
        builder: (context, state) {
          if (state is AttendanceLoading || state is AttendanceInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AttendanceError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<AttendanceCubit>().load(),
            );
          }
          if (state is AttendanceLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<AttendanceCubit>().load(),
              child: _buildContent(state),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(AttendanceLoaded state) {
    final status = state.status;
    final session = status.session;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statusCard(state),
        if (session != null) ...[
          const SizedBox(height: 16),
          _eventsCard(session),
        ],
        const SizedBox(height: 24),
        Text(
          'Recent attendance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (state.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No attendance history yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ...state.history.map((item) => _historyCard(item)),
      ],
    );
  }

  Widget _statusCard(AttendanceLoaded state) {
    final status = state.status;
    final session = status.session;
    final schedule = status.schedule;
    final location = status.location ?? session?.location;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today_outlined, color: AppColors.primaryStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _date(status.workDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SessionChip(
                  status: session?.status,
                  isWorkday: status.isWorkday,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.schedule,
              label: _windowLabel(status, schedule),
            ),
            if (location != null)
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: '${location.name} · ${location.timezone}',
              ),
            if (status.reason == 'schedule_missing')
              const _InfoRow(
                icon: Icons.warning_amber_outlined,
                label:
                    'No effective work schedule is assigned. Contact HR before recording attendance.',
              ),
            if (status.isWorkday == false)
              const _InfoRow(
                icon: Icons.event_busy_outlined,
                label:
                    'Today is outside your scheduled workdays. Attendance will be flagged for review.',
              ),
            const SizedBox(height: 16),
            if (status.canCheckIn)
              AppButton(
                text: 'Check in',
                isLoading: state.isPunching,
                onPressed: _canPunch(state) ? () => _confirmPunch(true) : null,
              )
            else if (status.canCheckOut)
              AppButton(
                text: 'Check out',
                isLoading: state.isPunching,
                onPressed: _canPunch(state) ? () => _confirmPunch(false) : null,
              )
            else
              Text(
                session == null
                    ? 'No attendance action is available right now.'
                    : 'Attendance is complete for this work date.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            if (status.canCheckIn || status.canCheckOut) ...[
              const SizedBox(height: 8),
              Text(
                'Location and face verification are required for every punch.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventsCard(AttendanceSessionModel session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: AppColors.primaryStrong),
                const SizedBox(width: 8),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...session.events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        _time(event.occurredAt),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_eventLabel(event.eventType)),
                          if (event.flags.isNotEmpty)
                            Text(
                              event.flags.map(_flagLabel).join(' · '),
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
              ),
            ),
            if (session.lateMinutes > 0)
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Late by ${session.lateMinutes} minute(s)',
              ),
            if (session.earlyDepartureMinutes > 0)
              _InfoRow(
                icon: Icons.timer_off_outlined,
                label:
                    'Early departure by ${session.earlyDepartureMinutes} minute(s)',
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(AttendanceSessionModel session) {
    final checkIn = session.checkInEvent;
    final checkOut = session.checkOutEvent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          _date(session.workDate),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${checkIn == null ? '--:--' : _time(checkIn.occurredAt)} – '
            '${checkOut == null ? '--:--' : _time(checkOut.occurredAt)}'
            '${session.location == null ? '' : ' · ${session.location!.name}'}',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        trailing: _SessionChip(status: session.status),
      ),
    );
  }

  bool _canPunch(AttendanceLoaded state) {
    return !state.isPunching;
  }

  Future<bool> _verifyFace(String challengeId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const FaceLivenessPage()),
    );
    return result == true;
  }

  Future<void> _confirmPunch(bool checkIn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(checkIn ? 'Check in?' : 'Check out?'),
        content: Text(
          checkIn
              ? 'Ravn will capture your current location and run on-device face liveness before recording check-in.'
              : 'Ravn will capture your current location and run on-device face liveness before recording check-out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(checkIn ? 'Check in' : 'Check out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AttendanceCubit>().punch(
      checkIn: checkIn,
      verifyFace: _verifyFace,
    );
  }

  String _windowLabel(
    AttendanceStatusModel status,
    AttendanceScheduleModel? schedule,
  ) {
    final start = status.scheduledStartAt == null
        ? schedule?.startTime
        : _time(status.scheduledStartAt);
    final end = status.scheduledEndAt == null
        ? schedule?.endTime
        : _time(status.scheduledEndAt);

    if (start == null && end == null) return 'No scheduled hours';
    return '${start ?? '--:--'} – ${end ?? '--:--'}'
        '${schedule?.overnight == true ? ' (overnight)' : ''}';
  }

  String _date(String? value) {
    if (value == null || value.isEmpty) return 'Today';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('EEE, d MMM yyyy').format(parsed);
  }

  String _time(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat.Hm().format(parsed.toLocal());
  }

  String _eventLabel(String type) {
    return type == 'check_in' ? 'Check in' : 'Check out';
  }

  String _flagLabel(String flag) {
    switch (flag) {
      case 'late':
        return 'Late';
      case 'early_departure':
        return 'Early departure';
      case 'outside_schedule':
        return 'Outside schedule';
      case 'corrected':
        return 'Corrected';
      default:
        return flag.replaceAll('_', ' ');
    }
  }
}

class _SessionChip extends StatelessWidget {
  final String? status;
  final bool? isWorkday;

  const _SessionChip({required this.status, this.isWorkday});

  @override
  Widget build(BuildContext context) {
    final label = status == 'closed'
        ? 'Complete'
        : status == 'open'
        ? 'Open'
        : isWorkday == false
        ? 'Flagged'
        : 'Not started';
    final color = status == 'closed'
        ? AppColors.success
        : status == 'open'
        ? AppColors.warning
        : isWorkday == false
        ? AppColors.danger
        : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
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
