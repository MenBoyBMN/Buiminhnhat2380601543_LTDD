class LeaveRequestModel {
  final int id;
  final String userId;
  final String fullName;
  final String? departmentName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.departmentName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      departmentName: json['departmentName'],
      leaveType: json['leaveType'] ?? 'Annual',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      reviewedBy: json['reviewedBy'],
      reviewNote: json['reviewNote'],
      createdAt: DateTime.parse(json['createdAt']),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
    );
  }

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  String get leaveTypeName {
    switch (leaveType) {
      case 'Annual':
        return 'Nghỉ phép năm';
      case 'Sick':
        return 'Nghỉ ốm đau';
      case 'Unpaid':
        return 'Nghỉ không lương';
      case 'Personal':
        return 'Việc riêng';
      default:
        return leaveType;
    }
  }
}
