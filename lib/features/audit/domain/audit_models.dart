class AuditLogItem {
  final int id;
  final String action; // CREATE, UPDATE, DELETE, FIRST_WEIGHT, SECOND_WEIGHT, CANCEL, CORRECT
  final String actionDisplay;
  final String modelName;
  final String objectRepr;
  final String userName;
  final String? userRole;
  final Map<String, dynamic>? changes;
  final String? reason;
  final String? ipAddress;
  final String? createdAtJalali;

  AuditLogItem({
    required this.id,
    required this.action,
    required this.actionDisplay,
    required this.modelName,
    required this.objectRepr,
    required this.userName,
    this.userRole,
    this.changes,
    this.reason,
    this.ipAddress,
    this.createdAtJalali,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    String actionLabel = 'تغییر';
    if (json['action_display'] is Map) {
      actionLabel = json['action_display']['label']?.toString() ?? 'تغییر';
    } else if (json['action_display'] is String && (json['action_display'] as String).isNotEmpty) {
      actionLabel = json['action_display'];
    }

    String uName = 'سیستم';
    final rawName = json['user_name']?.toString().trim();
    final rawUsername = json['username']?.toString().trim();
    if (rawName != null && rawName.isNotEmpty) {
      uName = rawName;
    } else if (rawUsername != null && rawUsername.isNotEmpty) {
      uName = rawUsername;
    } else if (json['user'] != null) {
      uName = 'کاربر #${json['user']}';
    }

    Map<String, dynamic>? changesMap;
    if (json['new_values'] is Map && (json['new_values'] as Map).isNotEmpty) {
      changesMap = Map<String, dynamic>.from(json['new_values'] as Map);
    } else if (json['changes'] is Map) {
      changesMap = Map<String, dynamic>.from(json['changes'] as Map);
    }

    return AuditLogItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      action: json['action']?.toString() ?? 'CHANGE',
      actionDisplay: actionLabel,
      modelName: json['model_name']?.toString() ?? json['content_type']?.toString() ?? 'سند',
      objectRepr: json['record_repr']?.toString().isNotEmpty == true
          ? json['record_repr'].toString()
          : (json['object_repr']?.toString() ?? ''),
      userName: uName,
      userRole: json['user_role']?.toString(),
      changes: changesMap,
      reason: json['reason']?.toString(),
      ipAddress: json['ip_address']?.toString(),
      createdAtJalali: json['timestamp_jalali']?.toString() ?? json['created_at_jalali']?.toString(),
    );
  }
}
