import 'package:json_annotation/json_annotation.dart';

part 'leave_models.g.dart';

@JsonSerializable()
class LeaveTypeModel {
  final int id;
  final String code;
  final String name;
  @JsonKey(name: 'requires_approval')
  final bool requiresApproval;
  final List<LeavePolicyModel> policies;

  const LeaveTypeModel({
    required this.id,
    required this.code,
    required this.name,
    required this.requiresApproval,
    required this.policies,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypeModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveTypeModelToJson(this);
}

@JsonSerializable()
class LeavePolicyModel {
  final int id;
  final String name;
  @JsonKey(name: 'annual_entitlement_days')
  final int annualEntitlementDays;
  @JsonKey(name: 'submission_deadline_days_before')
  final int? submissionDeadlineDaysBefore;
  @JsonKey(name: 'effective_from')
  final String? effectiveFrom;
  @JsonKey(name: 'effective_to')
  final String? effectiveTo;

  const LeavePolicyModel({
    required this.id,
    required this.name,
    required this.annualEntitlementDays,
    this.submissionDeadlineDaysBefore,
    this.effectiveFrom,
    this.effectiveTo,
  });

  factory LeavePolicyModel.fromJson(Map<String, dynamic> json) =>
      _$LeavePolicyModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeavePolicyModelToJson(this);
}

@JsonSerializable()
class LeaveBalanceModel {
  @JsonKey(name: 'leave_type')
  final LeaveTypeInfo leaveType;
  final int year;
  final double entitled;
  final double used;
  final double reserved;
  final double adjusted;
  final double available;

  const LeaveBalanceModel({
    required this.leaveType,
    required this.year,
    required this.entitled,
    required this.used,
    required this.reserved,
    required this.adjusted,
    required this.available,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveBalanceModelToJson(this);
}

@JsonSerializable()
class LeaveTypeInfo {
  final int id;
  final String code;
  final String name;

  const LeaveTypeInfo({
    required this.id,
    required this.code,
    required this.name,
  });

  factory LeaveTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveTypeInfoToJson(this);
}

@JsonSerializable()
class UserInfo {
  final int id;
  final String name;
  final String email;

  const UserInfo({required this.id, required this.name, required this.email});

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class WorkflowStepModel {
  final String key;
  final int position;
  final String status;
  @JsonKey(name: 'assignee_type')
  final String? assigneeType;
  @JsonKey(name: 'assignee_id')
  final int? assigneeId;
  @JsonKey(name: 'assignee_name')
  final String? assigneeName;
  @JsonKey(name: 'due_at')
  final String? dueAt;
  @JsonKey(name: 'acted_at')
  final String? actedAt;
  @JsonKey(name: 'acted_by')
  final int? actedBy;
  final String? action;

  const WorkflowStepModel({
    required this.key,
    required this.position,
    required this.status,
    this.assigneeType,
    this.assigneeId,
    this.assigneeName,
    this.dueAt,
    this.actedAt,
    this.actedBy,
    this.action,
  });

  factory WorkflowStepModel.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepModelFromJson(json);
  Map<String, dynamic> toJson() => _$WorkflowStepModelToJson(this);
}

@JsonSerializable()
class WorkflowModel {
  final int id;
  final String status;
  @JsonKey(name: 'current_step')
  final WorkflowStepModel? currentStep;
  final List<WorkflowStepModel> steps;

  const WorkflowModel({
    required this.id,
    required this.status,
    this.currentStep,
    required this.steps,
  });

  factory WorkflowModel.fromJson(Map<String, dynamic> json) =>
      _$WorkflowModelFromJson(json);
  Map<String, dynamic> toJson() => _$WorkflowModelToJson(this);
}

@JsonSerializable()
class LeaveRequestModel {
  final int id;
  final String status;
  final UserInfo employee;
  @JsonKey(name: 'leave_type')
  final LeaveTypeInfo? leaveType;
  final UserInfo? manager;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final double days;
  final String? reason;
  @JsonKey(name: 'submitted_at')
  final String? submittedAt;
  @JsonKey(name: 'canceled_at')
  final String? canceledAt;
  @JsonKey(name: 'cancel_reason')
  final String? cancelReason;
  final WorkflowModel? workflow;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const LeaveRequestModel({
    required this.id,
    required this.status,
    required this.employee,
    this.leaveType,
    this.manager,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.reason,
    this.submittedAt,
    this.canceledAt,
    this.cancelReason,
    this.workflow,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveRequestModelToJson(this);
}

@JsonSerializable()
class LeaveCancellationModel {
  final int id;
  @JsonKey(name: 'leave_request_id')
  final int leaveRequestId;
  final String status;
  final String reason;
  final UserInfo requester;
  final UserInfo? manager;
  @JsonKey(name: 'decided_by')
  final int? decidedBy;
  @JsonKey(name: 'decided_at')
  final String? decidedAt;
  final WorkflowModel? workflow;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const LeaveCancellationModel({
    required this.id,
    required this.leaveRequestId,
    required this.status,
    required this.reason,
    required this.requester,
    this.manager,
    this.decidedBy,
    this.decidedAt,
    this.workflow,
    this.createdAt,
  });

  factory LeaveCancellationModel.fromJson(Map<String, dynamic> json) =>
      _$LeaveCancellationModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveCancellationModelToJson(this);
}

@JsonSerializable()
class LeaveListResponse {
  final List<LeaveRequestModel> data;
  final Map<String, dynamic> meta;

  const LeaveListResponse({required this.data, required this.meta});

  factory LeaveListResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveListResponseToJson(this);
}

@JsonSerializable()
class LeaveBalanceListResponse {
  final List<LeaveBalanceModel> data;
  final Map<String, dynamic> meta;

  const LeaveBalanceListResponse({required this.data, required this.meta});

  factory LeaveBalanceListResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveBalanceListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveBalanceListResponseToJson(this);
}

@JsonSerializable()
class LeaveTypesResponse {
  final List<LeaveTypeModel> data;

  const LeaveTypesResponse({required this.data});

  factory LeaveTypesResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveTypesResponseToJson(this);
}

@JsonSerializable()
class LeaveRequestResponse {
  final LeaveRequestModel data;

  const LeaveRequestResponse({required this.data});

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveRequestResponseToJson(this);
}

@JsonSerializable()
class LeaveCancellationResponse {
  final LeaveCancellationModel data;

  const LeaveCancellationResponse({required this.data});

  factory LeaveCancellationResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveCancellationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveCancellationResponseToJson(this);
}

@JsonSerializable()
class LeaveCancellationListResponse {
  final List<LeaveCancellationModel> data;
  final Map<String, dynamic> meta;

  const LeaveCancellationListResponse({required this.data, required this.meta});

  factory LeaveCancellationListResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveCancellationListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveCancellationListResponseToJson(this);
}
