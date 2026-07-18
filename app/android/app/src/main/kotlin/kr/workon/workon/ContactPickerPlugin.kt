package kr.workon.workon

import android.app.Activity
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 기기 연락처 시스템 피커 브릿지(Android).
 * Intent.ACTION_PICK + Phone.CONTENT_URI 는 사용자가 고른 항목만 임시 접근을 허용하므로
 * READ_CONTACTS 권한이 불필요하다. 선택 결과의 이름/전화만 앱으로 돌려준다.
 */
class ContactPickerPlugin(private val activity: Activity) {
  companion object {
    const val CHANNEL = "kr.workon/contacts"
    const val REQ_PICK_CONTACT = 0xC047
  }

  private var pendingResult: MethodChannel.Result? = null

  fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "pickContact" -> pickContact(result)
      else -> result.notImplemented()
    }
  }

  private fun pickContact(result: MethodChannel.Result) {
    // 이미 진행 중이면 취소로 처리(중복 방지).
    if (pendingResult != null) {
      result.success(null)
      return
    }
    try {
      val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
      if (intent.resolveActivity(activity.packageManager) == null) {
        result.success(null)
        return
      }
      pendingResult = result
      activity.startActivityForResult(intent, REQ_PICK_CONTACT)
    } catch (e: Exception) {
      pendingResult = null
      result.success(null)
    }
  }

  /** MainActivity.onActivityResult 에서 위임. 처리 여부 반환. */
  fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != REQ_PICK_CONTACT) return false
    val result = pendingResult ?: return true
    pendingResult = null
    if (resultCode != Activity.RESULT_OK || data?.data == null) {
      result.success(null)
      return true
    }
    try {
      val cursor = activity.contentResolver.query(
        data.data!!,
        arrayOf(
          ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
          ContactsContract.CommonDataKinds.Phone.NUMBER,
        ),
        null, null, null,
      )
      cursor?.use {
        if (it.moveToFirst()) {
          val name = it.getString(0) ?: ""
          val phone = it.getString(1) ?: ""
          result.success(mapOf("name" to name, "phone" to phone))
          return true
        }
      }
      result.success(null)
    } catch (e: Exception) {
      result.success(null)
    }
    return true
  }
}
