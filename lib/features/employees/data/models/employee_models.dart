class EmployeeDirectoryPage {
  final List<EmployeeSummary> employees;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const EmployeeDirectoryPage({
    required this.employees,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory EmployeeDirectoryPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];

    return EmployeeDirectoryPage(
      employees: data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) =>
                      EmployeeSummary.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      currentPage: meta is Map ? _int(meta['current_page'], fallback: 1) : 1,
      perPage: meta is Map ? _int(meta['per_page'], fallback: 20) : 20,
      total: meta is Map ? _int(meta['total']) : 0,
      lastPage: meta is Map ? _int(meta['last_page'], fallback: 1) : 1,
    );
  }
}

class EmployeeSummary {
  final int id;
  final String employeeNo;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? workEmail;
  final String? hireDate;
  final EmployeeAssignmentInfo? currentAssignment;

  const EmployeeSummary({
    required this.id,
    required this.employeeNo,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.workEmail,
    this.hireDate,
    this.currentAssignment,
  });

  factory EmployeeSummary.fromJson(Map<String, dynamic> json) {
    final assignment = json['current_assignment'];

    return EmployeeSummary(
      id: _int(json['id']),
      employeeNo: _string(json['employee_no']),
      fullName: _string(json['full_name']),
      firstName: _nullableString(json['first_name']),
      lastName: _nullableString(json['last_name']),
      workEmail: _nullableString(json['work_email']),
      hireDate: _nullableString(json['hire_date']),
      currentAssignment: assignment is Map
          ? EmployeeAssignmentInfo.fromJson(
              Map<String, dynamic>.from(assignment),
            )
          : null,
    );
  }

  String get initials {
    final source = fullName.trim().isEmpty ? employeeNo : fullName.trim();
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get roleLabel {
    final position = currentAssignment?.position?.name;
    final department = currentAssignment?.department?.name;
    if (position != null && department != null) {
      return '$position · $department';
    }
    return position ?? department ?? 'Unassigned';
  }
}

class EmployeeProfile {
  final int id;
  final String employeeNo;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? workEmail;
  final String? hireDate;
  final EmployeeUserInfo? user;
  final EmployeeEmploymentInfo? currentEmployment;
  final EmployeeAssignmentInfo? currentAssignment;
  final List<EmployeeEmploymentInfo> employments;
  final List<EmployeeAssignmentInfo> assignments;

  const EmployeeProfile({
    required this.id,
    required this.employeeNo,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.phone,
    this.workEmail,
    this.hireDate,
    this.user,
    this.currentEmployment,
    this.currentAssignment,
    this.employments = const [],
    this.assignments = const [],
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final employment = json['current_employment'];
    final assignment = json['current_assignment'];
    final employments = json['employments'];
    final assignments = json['assignments'];

    return EmployeeProfile(
      id: _int(json['id']),
      employeeNo: _string(json['employee_no']),
      fullName: _string(json['full_name']),
      firstName: _nullableString(json['first_name']),
      lastName: _nullableString(json['last_name']),
      phone: _nullableString(json['phone']),
      workEmail: _nullableString(json['work_email']),
      hireDate: _nullableString(json['hire_date']),
      user: user is Map
          ? EmployeeUserInfo.fromJson(Map<String, dynamic>.from(user))
          : null,
      currentEmployment: employment is Map
          ? EmployeeEmploymentInfo.fromJson(
              Map<String, dynamic>.from(employment),
            )
          : null,
      currentAssignment: assignment is Map
          ? EmployeeAssignmentInfo.fromJson(
              Map<String, dynamic>.from(assignment),
            )
          : null,
      employments: employments is List
          ? employments
                .whereType<Map>()
                .map(
                  (item) => EmployeeEmploymentInfo.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      assignments: assignments is List
          ? assignments
                .whereType<Map>()
                .map(
                  (item) => EmployeeAssignmentInfo.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  String get initials {
    final source = fullName.trim().isEmpty ? employeeNo : fullName.trim();
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class EmployeeUserInfo {
  final int id;
  final String name;
  final String email;
  final String status;

  const EmployeeUserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  factory EmployeeUserInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeUserInfo(
      id: _int(json['id']),
      name: _string(json['name']),
      email: _string(json['email']),
      status: _string(json['status']),
    );
  }
}

class EmployeeEmploymentInfo {
  final int id;
  final String employmentType;
  final String effectiveFrom;
  final String? effectiveTo;
  final String status;

  const EmployeeEmploymentInfo({
    required this.id,
    required this.employmentType,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.status,
  });

  factory EmployeeEmploymentInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeEmploymentInfo(
      id: _int(json['id']),
      employmentType: _string(json['employment_type']),
      effectiveFrom: _string(json['effective_from']),
      effectiveTo: _nullableString(json['effective_to']),
      status: _string(json['status']),
    );
  }
}

class EmployeeAssignmentInfo {
  final int id;
  final EmployeeDepartmentInfo? department;
  final EmployeePositionInfo? position;
  final EmployeeManagerInfo? manager;
  final EmployeeWorkLocationInfo? workLocation;
  final String effectiveFrom;
  final String? effectiveTo;
  final String status;

  const EmployeeAssignmentInfo({
    required this.id,
    this.department,
    this.position,
    this.manager,
    this.workLocation,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.status,
  });

  factory EmployeeAssignmentInfo.fromJson(Map<String, dynamic> json) {
    final department = json['department'];
    final position = json['position'];
    final manager = json['manager'];
    final location = json['work_location'];

    return EmployeeAssignmentInfo(
      id: _int(json['id']),
      department: department is Map
          ? EmployeeDepartmentInfo.fromJson(
              Map<String, dynamic>.from(department),
            )
          : null,
      position: position is Map
          ? EmployeePositionInfo.fromJson(Map<String, dynamic>.from(position))
          : null,
      manager: manager is Map
          ? EmployeeManagerInfo.fromJson(Map<String, dynamic>.from(manager))
          : null,
      workLocation: location is Map
          ? EmployeeWorkLocationInfo.fromJson(
              Map<String, dynamic>.from(location),
            )
          : null,
      effectiveFrom: _string(json['effective_from']),
      effectiveTo: _nullableString(json['effective_to']),
      status: _string(json['status']),
    );
  }
}

class EmployeeDepartmentInfo {
  final int id;
  final String code;
  final String name;

  const EmployeeDepartmentInfo({
    required this.id,
    required this.code,
    required this.name,
  });

  factory EmployeeDepartmentInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeDepartmentInfo(
      id: _int(json['id']),
      code: _string(json['code']),
      name: _string(json['name']),
    );
  }
}

class EmployeePositionInfo {
  final int id;
  final String code;
  final String name;

  const EmployeePositionInfo({
    required this.id,
    required this.code,
    required this.name,
  });

  factory EmployeePositionInfo.fromJson(Map<String, dynamic> json) {
    return EmployeePositionInfo(
      id: _int(json['id']),
      code: _string(json['code']),
      name: _string(json['name']),
    );
  }
}

class EmployeeManagerInfo {
  final int id;
  final String name;
  final String email;

  const EmployeeManagerInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory EmployeeManagerInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeManagerInfo(
      id: _int(json['id']),
      name: _string(json['name']),
      email: _string(json['email']),
    );
  }
}

class EmployeeWorkLocationInfo {
  final int id;
  final String code;
  final String name;
  final String timezone;

  const EmployeeWorkLocationInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
  });

  factory EmployeeWorkLocationInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkLocationInfo(
      id: _int(json['id']),
      code: _string(json['code']),
      name: _string(json['name']),
      timezone: _string(json['timezone']),
    );
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _string(Object? value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
