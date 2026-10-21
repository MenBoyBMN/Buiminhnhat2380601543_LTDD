class ShiftModel {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final bool isActive;

  ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.isActive,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: json['startTime'] ?? '08:00',
      endTime: json['endTime'] ?? '17:00',
      gracePeriodMinutes: json['gracePeriodMinutes'] ?? 15,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'gracePeriodMinutes': gracePeriodMinutes,
      'isActive': isActive,
    };
  }
}
