class UserAccountItem {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String role;
  final bool isActive;
  final String? lastLoginJalali;

  UserAccountItem({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    required this.isActive,
    this.lastLoginJalali,
  });

  String get fullName => '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName';

  factory UserAccountItem.fromJson(Map<String, dynamic> json) {
    return UserAccountItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString(),
      role: (json['role_display'] is Map ? (json['role_display']['label'] ?? json['role_display']['code']) : json['role_name'] ?? json['role'] ?? 'اپراتور').toString(),
      isActive: json['is_active'] != false,
      lastLoginJalali: json['last_login_jalali']?.toString(),
    );
  }
}
