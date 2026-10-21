class UserModel {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final String? initials;
  final String role;
  final int? departmentId;
  final String? departmentName;
  final int streakCount;
  final int totalPoints;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    this.initials,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.streakCount = 0,
    this.totalPoints = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      initials: json['initials'],
      role: json['role'] ?? 'Employee',
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      streakCount: json['streakCount'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'fullName': fullName,
      'initials': initials,
      'role': role,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'streakCount': streakCount,
      'totalPoints': totalPoints,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isManager => role.toLowerCase() == 'manager';
  bool get isEmployee => role.toLowerCase() == 'employee';
}

class LoginStep1Result {
  final bool requireOtp;
  final String userName;
  final String email;
  final String message;
  final String demoOtp;

  LoginStep1Result({
    required this.requireOtp,
    required this.userName,
    required this.email,
    required this.message,
    required this.demoOtp,
  });

  factory LoginStep1Result.fromJson(Map<String, dynamic> json) {
    return LoginStep1Result(
      requireOtp: json['requireOtp'] ?? true,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      demoOtp: json['demoOtp'] ?? '',
    );
  }
}
