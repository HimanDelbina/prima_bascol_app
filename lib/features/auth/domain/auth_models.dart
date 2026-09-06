class AuthToken {
  final String access;
  final String refresh;

  AuthToken({required this.access, required this.refresh});

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      access: json['access']?.toString() ?? '',
      refresh: json['refresh']?.toString() ?? '',
    );
  }
}

class UserRole {
  final String code;
  final String label;

  UserRole({required this.code, required this.label});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class UserMe {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final UserRole role;
  final String mobile;
  final String personnelCode;
  final List<String> permissions;
  final bool isActive;

  UserMe({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    required this.mobile,
    required this.personnelCode,
    required this.permissions,
    required this.isActive,
  });

  bool hasPermission(String perm) => permissions.contains('*') || permissions.contains(perm);
  bool hasAnyPermission(List<String> perms) => permissions.contains('*') || perms.any((p) => permissions.contains(p));

  factory UserMe.fromJson(Map<String, dynamic> json) {
    var rawRole = json['role'];
    UserRole parsedRole;
    if (rawRole is Map<String, dynamic>) {
      parsedRole = UserRole.fromJson(rawRole);
    } else {
      parsedRole = UserRole(code: rawRole?.toString() ?? 'viewer', label: 'کاربر');
    }

    List<String> permsList = [];
    if (json['permissions'] is List) {
      permsList = (json['permissions'] as List).map((e) => e.toString()).toList();
    }

    return UserMe(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: parsedRole,
      mobile: json['mobile']?.toString() ?? '',
      personnelCode: json['personnel_code']?.toString() ?? '',
      permissions: permsList,
      isActive: json['is_active'] == true,
    );
  }
}
