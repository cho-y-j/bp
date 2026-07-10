import 'package:geolocator/geolocator.dart';

/// GPS 좌표(권한 거부/서비스 꺼짐 시 (0,0) 로 진행 — 백엔드는 위/경도 범위 내면 허용).
class GpsResult {
  final double lat;
  final double lng;
  final bool available;
  const GpsResult(this.lat, this.lng, this.available);
  static const none = GpsResult(0, 0, false);
}

Future<GpsResult> tryGetPosition() async {
  // GPS 는 절대 UI 를 막지 않는다: 전체를 하드 타임아웃으로 감싼다(권한/픽스 지연 방어).
  try {
    return await _getPosition()
        .timeout(const Duration(seconds: 6), onTimeout: () => GpsResult.none);
  } catch (_) {
    return GpsResult.none;
  }
}

Future<GpsResult> _getPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) return GpsResult.none;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    return GpsResult.none;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 5),
    ),
  );
  return GpsResult(pos.latitude, pos.longitude, true);
}
