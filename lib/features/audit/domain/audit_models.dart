class AuditLogItem {
  final int id;
  final String action; // CREATE, UPDATE, DELETE, FIRST_WEIGHT, SECOND_WEIGHT, CANCEL, CORRECT
  final String modelName;
  final String objectRepr;
  final String? userName;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? createdAtJalali;

  AuditLogItem({
    required this.id,
    required this.action,
    required this.modelName,
    required this.objectRepr,
    this.userName,
    this.changes,
    this.ipAddress,
    this.createdAtJalali,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      action: json['action']?.toString() ?? 'CHANGE',
      modelName: json['model_name']?.toString() ?? json['content_type']?.toString() ?? 'سند',
      objectRepr: json['object_repr']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['user']?.toString(),
      changes: json['changes'] as Map<String, dynamic>?,
      ipAddress: json['ip_address']?.toString(),
      createdAtJalali: json['created_at_jalali']?.toString() ?? json['timestamp_jalali']?.toString(),
    );
  }
}
