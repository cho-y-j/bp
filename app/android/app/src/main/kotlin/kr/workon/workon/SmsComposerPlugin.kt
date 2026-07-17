package kr.workon.workon

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Telephony
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 문자 작성창 브릿지(Android).
 *  - 텍스트만: ACTION_SENDTO smsto:번호 + sms_body (수신인·본문 프리필).
 *  - 이미지/PDF: ACTION_SEND + FileProvider URI + EXTRA_TEXT + 기본 문자앱 지정,
 *    미설치·실패 시 일반 공유(chooser) 폴백.
 */
class SmsComposerPlugin(private val activity: Activity) {
  companion object {
    const val CHANNEL = "kr.workon/sms"
  }

  fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "canSendText" -> result.success(true)
      "canSendAttachments" -> result.success(true)
      "compose" -> compose(call, result)
      else -> result.notImplemented()
    }
  }

  private fun compose(call: MethodCall, result: MethodChannel.Result) {
    val recipients = call.argument<List<String>>("recipients") ?: emptyList()
    val body = call.argument<String>("body") ?: ""
    val attachments = call.argument<List<String>>("attachments") ?: emptyList()

    try {
      if (attachments.isEmpty()) {
        return composeText(recipients, body, result)
      }
      composeWithAttachment(recipients, body, attachments, result)
    } catch (e: Exception) {
      result.success("failed")
    }
  }

  /** 텍스트 문자 — smsto: 로 수신인+본문 프리필. */
  private fun composeText(
    recipients: List<String>,
    body: String,
    result: MethodChannel.Result,
  ) {
    val to = recipients.joinToString(";")
    val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$to")).apply {
      putExtra("sms_body", body)
    }
    // 기본 문자앱으로 우선 지정(있으면).
    Telephony.Sms.getDefaultSmsPackage(activity)?.let { intent.setPackage(it) }
    if (intent.resolveActivity(activity.packageManager) != null) {
      activity.startActivity(intent)
      result.success("composed")
      return
    }
    // 기본앱 지정으로 실패 시 패키지 제한 없이 재시도.
    val plain = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$to")).apply {
      putExtra("sms_body", body)
    }
    if (plain.resolveActivity(activity.packageManager) != null) {
      activity.startActivity(plain)
      result.success("composed")
    } else {
      result.success("unsupported")
    }
  }

  /** 이미지/PDF 첨부 — ACTION_SEND(단일) 또는 SEND_MULTIPLE. */
  private fun composeWithAttachment(
    recipients: List<String>,
    body: String,
    attachments: List<String>,
    result: MethodChannel.Result,
  ) {
    val authority = "${activity.packageName}.fileprovider"
    val uris = ArrayList<Uri>()
    var mime = "image/*"
    for (path in attachments) {
      val f = File(path)
      if (!f.exists()) continue
      uris.add(FileProvider.getUriForFile(activity, authority, f))
      if (path.lowercase().endsWith(".pdf")) mime = "application/pdf"
    }
    if (uris.isEmpty()) {
      return composeText(recipients, body, result)
    }

    val intent = if (uris.size == 1) {
      Intent(Intent.ACTION_SEND).apply {
        type = mime
        putExtra(Intent.EXTRA_STREAM, uris[0])
      }
    } else {
      Intent(Intent.ACTION_SEND_MULTIPLE).apply {
        type = mime
        putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
      }
    }
    intent.putExtra(Intent.EXTRA_TEXT, body)
    if (recipients.isNotEmpty()) {
      intent.putExtra("address", recipients.joinToString(";"))
    }
    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

    // 기본 문자앱으로 우선 시도.
    val smsPkg = Telephony.Sms.getDefaultSmsPackage(activity)
    if (smsPkg != null) {
      val direct = Intent(intent).setPackage(smsPkg)
      if (direct.resolveActivity(activity.packageManager) != null) {
        activity.startActivity(direct)
        result.success("composed")
        return
      }
    }
    // 폴백: 일반 공유 시트(Messages 포함).
    val chooser = Intent.createChooser(intent, null)
    if (intent.resolveActivity(activity.packageManager) != null) {
      activity.startActivity(chooser)
      result.success("shared")
    } else {
      result.success("unsupported")
    }
  }
}
