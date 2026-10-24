// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  status: json['status'] as String,
  employeeId: (json['employee_id'] as num?)?.toInt(),
  lastLoginAt: json['last_login_at'] as String?,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'status': instance.status,
  'employee_id': instance.employeeId,
  'last_login_at': instance.lastLoginAt,
  'roles': instance.roles,
  'permissions': instance.permissions,
};
