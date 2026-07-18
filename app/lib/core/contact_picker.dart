import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 기기 연락처 시스템 피커 브릿지.
///  - iOS: CNContactPickerViewController (권한 불필요, out-of-process).
///  - Android: Intent.ACTION_PICK (Phone.CONTENT_URI, 선택 항목만 임시 접근 → 권한 불필요).
/// READ_CONTACTS 권한을 요구하지 않는다.
class ContactPicker {
  static const MethodChannel _ch = MethodChannel('kr.workon/contacts');

  /// 시스템 연락처 피커를 열어 {name, phone} 을 받는다.
  /// 취소/실패/미지원이면 null.
  Future<({String name, String phone})?> pick() async {
    try {
      final res = await _ch.invokeMethod<Map>('pickContact');
      if (res == null) return null;
      final name = res['name']?.toString() ?? '';
      final phone = res['phone']?.toString() ?? '';
      if (phone.isEmpty && name.isEmpty) return null;
      return (name: name, phone: phone);
    } on MissingPluginException {
      // 채널 미등록(테스트/미지원 플랫폼) → 무동작.
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[ContactPicker] pick error: $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[ContactPicker] pick error: $e');
      return null;
    }
  }
}
