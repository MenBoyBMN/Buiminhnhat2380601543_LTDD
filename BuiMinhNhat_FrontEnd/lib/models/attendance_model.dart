class AttendanceRecordModel {
  final int id;
  final String userId;
  final String fullName;
  final String? departmentName;
  final String? shiftName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double distanceMeters;
  final bool isWithinGeofence;
  final String? qrTokenUsed;
  final String? photoUrl;
  final String? mood;
  final String? note;
  final String status;
  final int pointsEarned;

  AttendanceRecordModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.departmentName,
    this.shiftName,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.distanceMeters,
    required this.isWithinGeofence,
    this.qrTokenUsed,
    this.photoUrl,
    this.mood,
    this.note,
    required this.status,
    required this.pointsEarned,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      departmentName: json['departmentName'],
      shiftName: json['shiftName'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      isWithinGeofence: json['isWithinGeofence'] ?? false,
      qrTokenUsed: json['qrTokenUsed'],
      photoUrl: json['photoUrl'],
      mood: json['mood'],
      note: json['note'],
      status: json['status'] ?? 'OnTime',
      pointsEarned: json['pointsEarned'] ?? 10,
    );
  }
}

class LeaderboardItemModel {
  final int rank;
  final String userId;
  final String fullName;
  final String? departmentName;
  final int streakCount;
  final int totalPoints;

  LeaderboardItemModel({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.departmentName,
    required this.streakCount,
    required this.totalPoints,
  });

  factory LeaderboardItemModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardItemModel(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      departmentName: json['departmentName'],
      streakCount: json['streakCount'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
    );
  }
}

class QrSessionModel {
  final String tokenCode;
  final int? shiftId;
  final DateTime expiresAt;
  final int remainingSeconds;

  QrSessionModel({
    required this.tokenCode,
    this.shiftId,
    required this.expiresAt,
    required this.remainingSeconds,
  });

  factory QrSessionModel.fromJson(Map<String, dynamic> json) {
    return QrSessionModel(
      tokenCode: json['tokenCode'] ?? '',
      shiftId: json['shiftId'],
      expiresAt: DateTime.parse(json['expiresAt']),
      remainingSeconds: json['remainingSeconds'] ?? 60,
    );
  }
}
