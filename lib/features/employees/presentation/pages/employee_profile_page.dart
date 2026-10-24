import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/employee_models.dart';
import '../cubit/employee_profile_cubit.dart';

class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<EmployeeProfileCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<EmployeeProfileCubit, EmployeeProfileState>(
        builder: (context, state) {
          if (state is EmployeeProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmployeeProfileError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<EmployeeProfileCubit>().load(),
            );
          }

          if (state is EmployeeProfileLoaded) {
            return _ProfileBody(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final EmployeeProfileLoaded state;

  const _ProfileBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final assignment = profile.currentAssignment;
    final auth = context.read<AuthCubit>().state;
    final canViewHistory =
        auth is AuthAuthenticated &&
        auth.user.permissions.contains('employees.view_history');

    return RefreshIndicator(
      onRefresh: () => context.read<EmployeeProfileCubit>().load(
        includeHistory: state.includeHistory,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Contact',
            icon: HeroiconsOutline.envelope,
            children: [
              _InfoRow(label: 'Work email', value: profile.workEmail ?? '—'),
              _InfoRow(label: 'Phone', value: profile.phone ?? '—'),
              _InfoRow(label: 'Hire date', value: formatDate(profile.hireDate)),
              _InfoRow(
                label: 'Account',
                value: profile.user?.email ?? 'No linked account',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Current assignment',
            icon: HeroiconsOutline.briefcase,
            children: [
              _InfoRow(
                label: 'Department',
                value: assignment?.department?.name ?? '—',
              ),
              _InfoRow(
                label: 'Position',
                value: assignment?.position?.name ?? '—',
              ),
              _InfoRow(
                label: 'Manager',
                value: assignment?.manager?.name ?? '—',
              ),
              _InfoRow(
                label: 'Work location',
                value: assignment?.workLocation?.name ?? '—',
              ),
              _InfoRow(
                label: 'Timezone',
                value: assignment?.workLocation?.timezone ?? '—',
              ),
              _InfoRow(
                label: 'Effective from',
                value: formatDate(assignment?.effectiveFrom),
              ),
              _InfoRow(
                label: 'Effective to',
                value: assignment?.effectiveTo == null
                    ? 'Open-ended'
                    : formatDate(assignment?.effectiveTo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Employment',
            icon: HeroiconsOutline.documentText,
            children: [
              _InfoRow(
                label: 'Type',
                value: profile.currentEmployment?.employmentType ?? '—',
              ),
              _InfoRow(
                label: 'Effective from',
                value: formatDate(profile.currentEmployment?.effectiveFrom),
              ),
              _InfoRow(
                label: 'Status',
                value: profile.currentEmployment?.status ?? '—',
              ),
            ],
          ),
          if (canViewHistory) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'History',
              icon: HeroiconsOutline.clock,
              children: [
                if (state.includeHistory) ...[
                  if (profile.employments.isEmpty)
                    const _EmptyHistory(label: 'No employment history')
                  else
                    ...profile.employments.map(
                      (employment) => _HistoryTile(
                        title: employment.employmentType,
                        subtitle:
                            '${formatDate(employment.effectiveFrom)} → ${employment.effectiveTo == null ? 'Open-ended' : formatDate(employment.effectiveTo)}',
                        status: employment.status,
                      ),
                    ),
                  if (profile.assignments.isEmpty)
                    const _EmptyHistory(label: 'No assignment history')
                  else
                    ...profile.assignments.map(
                      (assignment) => _HistoryTile(
                        title:
                            '${assignment.position?.name ?? 'Assignment'} · ${assignment.department?.name ?? 'Unassigned'}',
                        subtitle:
                            '${formatDate(assignment.effectiveFrom)} → ${assignment.effectiveTo == null ? 'Open-ended' : formatDate(assignment.effectiveTo)}',
                        status: assignment.status,
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<EmployeeProfileCubit>().toggleHistory(),
                    child: const Text('Hide history'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: () =>
                        context.read<EmployeeProfileCubit>().toggleHistory(),
                    child: const Text('Show history'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final EmployeeProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: AppColors.primaryStrong,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.employeeNo,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label:
                            profile.currentAssignment?.position?.name ??
                            'Unassigned',
                        color: AppColors.primaryContainer,
                        textColor: AppColors.primaryStrong,
                      ),
                      if (profile.currentAssignment?.department?.name != null)
                        _Pill(
                          label: profile.currentAssignment!.department!.name,
                          color: AppColors.surface,
                          textColor: AppColors.textMuted,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryStrong),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            HeroiconsOutline.chevronRight,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final String label;

  const _EmptyHistory({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
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
              HeroiconsOutline.exclamationTriangle,
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
