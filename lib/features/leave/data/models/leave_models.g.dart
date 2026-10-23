// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveTypeModel _$LeaveTypeModelFromJson(Map<String, dynamic> json) =>
    LeaveTypeModel(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      requiresApproval: json['requires_approval'] as bool,
      policies: (json['policies'] as List<dynamic>)
          .map((e) => LeavePolicyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LeaveTypeModelToJson(LeaveTypeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'requires_approval': instance.requiresApproval,
      'policies': instance.policies,
    };

LeavePolicyModel _$LeavePolicyModelFromJson(Map<String, dynamic> json) =>
    LeavePolicyModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      annualEntitlementDays: (json['annual_entitlement_days'] as num).toInt(),
      submissionDeadlineDaysBefore:
          (json['submission_deadline_days_before'] as num?)?.toInt(),
      effectiveFrom: json['effective_from'] as String?,
      effectiveTo: json['effective_to'] as String?,
    );

Map<String, dynamic> _$LeavePolicyModelToJson(LeavePolicyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'annual_entitlement_days': instance.annualEntitlementDays,
      'submission_deadline_days_before': instance.submissionDeadlineDaysBefore,
      'effective_from': instance.effectiveFrom,
      'effective_to': instance.effectiveTo,
    };

LeaveBalanceModel _$LeaveBalanceModelFromJson(Map<String, dynamic> json) =>
    LeaveBalanceModel(
      leaveType: LeaveTypeInfo.fromJson(
        json['leave_type'] as Map<String, dynamic>,
      ),
      year: (json['year'] as num).toInt(),
      entitled: (json['entitled'] as num).toDouble(),
      used: (json['used'] as num).toDouble(),
      reserved: (json['reserved'] as num).toDouble(),
      adjusted: (json['adjusted'] as num).toDouble(),
      available: (json['available'] as num).toDouble(),
    );

Map<String, dynamic> _$LeaveBalanceModelToJson(LeaveBalanceModel instance) =>
    <String, dynamic>{
      'leave_type': instance.leaveType,
      'year': instance.year,
      'entitled': instance.entitled,
      'used': instance.used,
      'reserved': instance.reserved,
      'adjusted': instance.adjusted,
      'available': instance.available,
    };

LeaveTypeInfo _$LeaveTypeInfoFromJson(Map<String, dynamic> json) =>
    LeaveTypeInfo(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LeaveTypeInfoToJson(LeaveTypeInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
};

WorkflowStepModel _$WorkflowStepModelFromJson(Map<String, dynamic> json) =>
    WorkflowStepModel(
      key: json['key'] as String,
      position: (json['position'] as num).toInt(),
      status: json['status'] as String,
      assigneeType: json['assignee_type'] as String?,
      assigneeId: (json['assignee_id'] as num?)?.toInt(),
      assigneeName: json['assignee_name'] as String?,
      dueAt: json['due_at'] as String?,
      actedAt: json['acted_at'] as String?,
      actedBy: (json['acted_by'] as num?)?.toInt(),
      action: json['action'] as String?,
    );

Map<String, dynamic> _$WorkflowStepModelToJson(WorkflowStepModel instance) =>
    <String, dynamic>{
      'key': instance.key,
      'position': instance.position,
      'status': instance.status,
      'assignee_type': instance.assigneeType,
      'assignee_id': instance.assigneeId,
      'assignee_name': instance.assigneeName,
      'due_at': instance.dueAt,
      'acted_at': instance.actedAt,
      'acted_by': instance.actedBy,
      'action': instance.action,
    };

WorkflowModel _$WorkflowModelFromJson(Map<String, dynamic> json) =>
    WorkflowModel(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      currentStep: json['current_step'] == null
          ? null
          : WorkflowStepModel.fromJson(
              json['current_step'] as Map<String, dynamic>,
            ),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => WorkflowStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkflowModelToJson(WorkflowModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'current_step': instance.currentStep,
      'steps': instance.steps,
    };

LeaveRequestModel _$LeaveRequestModelFromJson(Map<String, dynamic> json) =>
    LeaveRequestModel(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      employee: UserInfo.fromJson(json['employee'] as Map<String, dynamic>),
      leaveType: json['leave_type'] == null
          ? null
          : LeaveTypeInfo.fromJson(json['leave_type'] as Map<String, dynamic>),
      manager: json['manager'] == null
          ? null
          : UserInfo.fromJson(json['manager'] as Map<String, dynamic>),
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      days: (json['days'] as num).toDouble(),
      reason: json['reason'] as String?,
      submittedAt: json['submitted_at'] as String?,
      canceledAt: json['canceled_at'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      workflow: json['workflow'] == null
          ? null
          : WorkflowModel.fromJson(json['workflow'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$LeaveRequestModelToJson(LeaveRequestModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'employee': instance.employee,
      'leave_type': instance.leaveType,
      'manager': instance.manager,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'days': instance.days,
      'reason': instance.reason,
      'submitted_at': instance.submittedAt,
      'canceled_at': instance.canceledAt,
      'cancel_reason': instance.cancelReason,
      'workflow': instance.workflow,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

LeaveCancellationModel _$LeaveCancellationModelFromJson(
  Map<String, dynamic> json,
) => LeaveCancellationModel(
  id: (json['id'] as num).toInt(),
  leaveRequestId: (json['leave_request_id'] as num).toInt(),
  status: json['status'] as String,
  reason: json['reason'] as String,
  requester: UserInfo.fromJson(json['requester'] as Map<String, dynamic>),
  manager: json['manager'] == null
      ? null
      : UserInfo.fromJson(json['manager'] as Map<String, dynamic>),
  decidedBy: (json['decided_by'] as num?)?.toInt(),
  decidedAt: json['decided_at'] as String?,
  workflow: json['workflow'] == null
      ? null
      : WorkflowModel.fromJson(json['workflow'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$LeaveCancellationModelToJson(
  LeaveCancellationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'leave_request_id': instance.leaveRequestId,
  'status': instance.status,
  'reason': instance.reason,
  'requester': instance.requester,
  'manager': instance.manager,
  'decided_by': instance.decidedBy,
  'decided_at': instance.decidedAt,
  'workflow': instance.workflow,
  'created_at': instance.createdAt,
};

LeaveListResponse _$LeaveListResponseFromJson(Map<String, dynamic> json) =>
    LeaveListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LeaveListResponseToJson(LeaveListResponse instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};

LeaveBalanceListResponse _$LeaveBalanceListResponseFromJson(
  Map<String, dynamic> json,
) => LeaveBalanceListResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => LeaveBalanceModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] as Map<String, dynamic>,
);

Map<String, dynamic> _$LeaveBalanceListResponseToJson(
  LeaveBalanceListResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};

LeaveTypesResponse _$LeaveTypesResponseFromJson(Map<String, dynamic> json) =>
    LeaveTypesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => LeaveTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LeaveTypesResponseToJson(LeaveTypesResponse instance) =>
    <String, dynamic>{'data': instance.data};

LeaveRequestResponse _$LeaveRequestResponseFromJson(
  Map<String, dynamic> json,
) => LeaveRequestResponse(
  data: LeaveRequestModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LeaveRequestResponseToJson(
  LeaveRequestResponse instance,
) => <String, dynamic>{'data': instance.data};

LeaveCancellationResponse _$LeaveCancellationResponseFromJson(
  Map<String, dynamic> json,
) => LeaveCancellationResponse(
  data: LeaveCancellationModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LeaveCancellationResponseToJson(
  LeaveCancellationResponse instance,
) => <String, dynamic>{'data': instance.data};

LeaveCancellationListResponse _$LeaveCancellationListResponseFromJson(
  Map<String, dynamic> json,
) => LeaveCancellationListResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => LeaveCancellationModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] as Map<String, dynamic>,
);

Map<String, dynamic> _$LeaveCancellationListResponseToJson(
  LeaveCancellationListResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
