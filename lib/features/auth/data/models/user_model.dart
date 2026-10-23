import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;
  final String status;
  @JsonKey(name: 'last_login_at')
  final String? lastLoginAt;
  final List<String> roles;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.lastLoginAt,
    required this.roles,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
