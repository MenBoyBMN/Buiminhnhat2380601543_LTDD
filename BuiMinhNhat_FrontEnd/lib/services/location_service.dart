import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Lấy vị trí GPS hiện tại của người dùng kèm xử lý quyền hạn và fallback
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Trả về vị trí mặc định nếu GPS tắt (Hỗ trợ demo máy ảo/desktop)
      return _defaultPosition();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _defaultPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _defaultPosition();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return _defaultPosition();
    }
  }

  /// Tọa độ mặc định (Trụ sở văn phòng: 280 An Dương Vương, Q5, TP.HCM)
  static Position _defaultPosition() {
    return Position(
      latitude: 10.759917,
      longitude: 106.682258,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 1.0,
    );
  }
}
