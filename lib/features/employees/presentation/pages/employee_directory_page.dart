import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/employee_models.dart';
import '../cubit/employee_directory_cubit.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<EmployeeDirectoryCubit>().search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<EmployeeDirectoryCubit>().load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, employee number or email',
                prefixIcon: const Icon(HeroiconsOutline.magnifyingGlass),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          context.read<EmployeeDirectoryCubit>().search('');
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<EmployeeDirectoryCubit, EmployeeDirectoryState>(
              builder: (context, state) {
                if (state is EmployeeDirectoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EmployeeDirectoryError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<EmployeeDirectoryCubit>().load(),
                  );
                }

                if (state is EmployeeDirectoryLoaded) {
                  return _buildList(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(EmployeeDirectoryLoaded state) {
    if (state.employees.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<EmployeeDirectoryCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            Icon(HeroiconsOutline.users, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Center(
              child: Text(
                state.query.isEmpty
                    ? 'No employee profiles yet'
                    : 'No matches for "${state.query}"',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EmployeeDirectoryCubit>().load(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.employees.length + 1,
        itemBuilder: (context, index) {
          if (index == state.employees.length) {
            return _buildFooter(state);
          }

          final employee = state.employees[index];
          return _EmployeeCard(
            employee: employee,
            onTap: () => context.push('/directory/${employee.id}'),
          );
        },
      ),
    );
  }

  Widget _buildFooter(EmployeeDirectoryLoaded state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<EmployeeDirectoryCubit>().loadMore(),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (state.currentPage < state.lastPage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: () => context.read<EmployeeDirectoryCubit>().loadMore(),
          child: const Text('Load more'),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeSummary employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            employee.initials,
            style: const TextStyle(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(employee.roleLabel),
            if (employee.workEmail != null) ...[
              const SizedBox(height: 2),
              Text(
                employee.workEmail!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
