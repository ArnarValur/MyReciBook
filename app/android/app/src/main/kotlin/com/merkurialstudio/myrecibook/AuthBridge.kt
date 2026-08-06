package com.merkurialstudio.myrecibook

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// OAuth leg: launches the system browser and captures the
// com.merkurialstudio.myrecibook://oauth2 redirect back into Dart.
// A hostile/malformed url or redirect must no-op, never crash.
class AuthBridge(private val activity: Activity) {
  private var channel: MethodChannel? = null
  private val pending = mutableListOf<String>() // main-thread only

  companion object {
    private const val CHANNEL = "com.merkurialstudio.myrecibook/auth"
    private const val REDIRECT_SCHEME = "com.merkurialstudio.myrecibook"
    private const val REDIRECT_HOST = "oauth2"
  }

  fun attach(messenger: BinaryMessenger) {
    channel = MethodChannel(messenger, CHANNEL).also { ch ->
      ch.setMethodCallHandler { call, result ->
        when (call.method) {
          "launchUrl" -> launchUrl(call.arguments as? String, result)
          "takePendingRedirects" -> {
            result.success(pending.toList())
            pending.clear()
          }
          else -> result.notImplemented()
        }
      }
    }
  }

  private fun launchUrl(url: String?, result: MethodChannel.Result) {
    try {
      val uri = Uri.parse(url ?: throw IllegalArgumentException("missing url"))
      require(uri.scheme == "https") { "refusing non-https url" }
      activity.startActivity(Intent(Intent.ACTION_VIEW, uri))
      result.success(null)
    } catch (e: Exception) {
      result.error("AUTH_IO", e.message ?: e.javaClass.simpleName, null)
    }
  }

  // True when the intent is our oauth2 redirect — routing owns the
  // auth/share split, a redirect must never reach ShareBridge.
  fun handleIntent(intent: Intent?): Boolean {
    val uri = intent?.data ?: return false
    if (uri.scheme != REDIRECT_SCHEME || uri.host != REDIRECT_HOST) return false
    deliver(uri.toString())
    return true
  }

  // Queue first; the warm push only un-queues on confirmed Dart delivery, so
  // a cold start keeps the uri for takePendingRedirects (ShareBridge pattern).
  private fun deliver(uriString: String) {
    pending.add(uriString)
    val ch = channel ?: return
    ch.invokeMethod("onAuthRedirect", uriString, object : MethodChannel.Result {
      override fun success(result: Any?) {
        pending.remove(uriString)
      }

      override fun error(code: String, message: String?, details: Any?) {}

      override fun notImplemented() {}
    })
  }
}
