class DepartmentModel {
  final int id;
  final String name;
  final String? description;
  final String? officeAddress;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int userCount;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.officeAddress,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.userCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      officeAddress: json['officeAddress'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.759917,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.682258,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 300.0,
      userCount: json['userCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'officeAddress': officeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }
}
