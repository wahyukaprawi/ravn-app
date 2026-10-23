import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/leave_models.dart';
import '../cubit/leave_cubit.dart';

class LeaveSubmitPage extends StatefulWidget {
  const LeaveSubmitPage({super.key});

  @override
  State<LeaveSubmitPage> createState() => _LeaveSubmitPageState();
}

class _LeaveSubmitPageState extends State<LeaveSubmitPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedTypeId;
  List<LeaveTypeModel> _types = const [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Leave Request')),
      body: BlocConsumer<LeaveCubit, LeaveState>(
        listener: (context, state) {
          if (state is LeaveSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leave request submitted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
          if (state is LeaveError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is LeaveSubmitting;
          if (state is LeaveLoaded) {
            _types = state.types;
          }
          final types = _types;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leave Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedTypeId,
                            decoration: const InputDecoration(
                              hintText: 'Select leave type',
                            ),
                            items: types.map<DropdownMenuItem<int>>((type) {
                              return DropdownMenuItem<int>(
                                value: type.id,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a leave type';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Start Date'),
                            subtitle: Text(
                              _startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                  : 'Select date',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _selectStartDate,
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('End Date'),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                  : 'Select date',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _startDate != null ? _selectEndDate : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reasonController,
                            decoration: const InputDecoration(
                              hintText: 'Enter reason for leave',
                            ),
                            maxLines: 4,
                            maxLength: 2000,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Submit Request',
                    isLoading: isSubmitting,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_startDate == null || _endDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select start and end dates',
                              ),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        context.read<LeaveCubit>().submitRequest(
                          leaveTypeId: _selectedTypeId!,
                          startDate: DateFormat(
                            'yyyy-MM-dd',
                          ).format(_startDate!),
                          endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
                          reason: _reasonController.text,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
