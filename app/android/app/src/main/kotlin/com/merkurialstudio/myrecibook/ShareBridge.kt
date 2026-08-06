package com.merkurialstudio.myrecibook

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong

// Share-sheet intake. Content grants die with the delivering intent (arch §8),
// so every shared image is copied into cacheDir/shared before Dart sees a path.
// A hostile/malformed share must no-op, never crash.
class ShareBridge(private val activity: Activity) {
  private var channel: MethodChannel? = null
  private val pending = mutableListOf<String>() // main-thread only
  private val io = Executors.newSingleThreadExecutor()
  private val main = Handler(Looper.getMainLooper())
  private val seq = AtomicLong(0)

  companion object {
    private const val CHANNEL = "com.merkurialstudio.myrecibook/share"
    private const val MAX_IMAGES = 10
    private const val MAX_BYTES = 25L * 1024 * 1024
  }

  fun attach(messenger: BinaryMessenger) {
    channel = MethodChannel(messenger, CHANNEL).also { ch ->
      ch.setMethodCallHandler { call, result ->
        when (call.method) {
          "takePendingShared" -> {
            result.success(pending.toList())
            pending.clear()
          }
          else -> result.notImplemented()
        }
      }
    }
  }

  fun handleIntent(intent: Intent?) {
    val uris = try {
      extractImageUris(intent)
    } catch (_: Exception) {
      emptyList()
    }
    if (uris.isEmpty()) return
    io.execute {
      val paths = uris.take(MAX_IMAGES).mapNotNull { copyToCache(it, intent) }
      if (paths.isNotEmpty()) main.post { deliver(paths) }
    }
  }

  // Queue first; the warm-app push only un-queues on confirmed Dart delivery,
  // so a cold start still drains everything via takePendingShared.
  private fun deliver(paths: List<String>) {
    pending.addAll(paths)
    val ch = channel ?: return
    ch.invokeMethod("onSharedImages", paths, object : MethodChannel.Result {
      override fun success(result: Any?) {
        pending.removeAll(paths)
      }

      override fun error(code: String, message: String?, details: Any?) {}

      override fun notImplemented() {}
    })
  }

  @Suppress("DEPRECATION")
  private fun extractImageUris(intent: Intent?): List<Uri> {
    intent ?: return emptyList()
    val raw: List<Uri> = when (intent.action) {
      Intent.ACTION_SEND -> listOfNotNull(
        if (Build.VERSION.SDK_INT >= 33)
          intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else
          intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
      )
      Intent.ACTION_SEND_MULTIPLE ->
        (if (Build.VERSION.SDK_INT >= 33)
          intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else
          intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM))
          ?.filterIsInstance<Uri>() ?: emptyList()
      else -> emptyList()
    }
    return raw.filter { mimeOf(it, intent)?.startsWith("image/") == true }
  }

  private fun mimeOf(uri: Uri, intent: Intent?): String? =
    try {
      activity.contentResolver.getType(uri) ?: intent?.type
    } catch (_: Exception) {
      null
    }

  private fun copyToCache(uri: Uri, intent: Intent?): String? {
    return try {
      val declared = querySize(uri)
      if (declared != null && declared > MAX_BYTES) return null
      val dir = File(activity.cacheDir, "shared")
      dir.mkdirs()
      val ext = guessExtension(uri, intent)
      val out = File(dir, "share-${System.currentTimeMillis()}-${seq.incrementAndGet()}.$ext")
      var total = 0L
      var oversize = false
      activity.contentResolver.openInputStream(uri)?.use { input ->
        out.outputStream().use { output ->
          val buf = ByteArray(64 * 1024)
          while (true) {
            val n = input.read(buf)
            if (n < 0) break
            total += n
            if (total > MAX_BYTES) { // provider lied about (or omitted) size
              oversize = true
              break
            }
            output.write(buf, 0, n)
          }
        }
      } ?: return null
      if (oversize) {
        out.delete()
        return null
      }
      out.absolutePath
    } catch (_: Exception) {
      null
    }
  }

  private fun querySize(uri: Uri): Long? =
    try {
      activity.contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)
        ?.use { c ->
          if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null
        }
    } catch (_: Exception) {
      null
    }

  private fun guessExtension(uri: Uri, intent: Intent?): String {
    val fromMime = mimeOf(uri, intent)
      ?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
    if (fromMime != null) return fromMime
    val name = try {
      activity.contentResolver.query(
        uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null
      )?.use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getString(0) else null }
    } catch (_: Exception) {
      null
    }
    val fromName = name?.substringAfterLast('.', "")?.takeIf { it.isNotEmpty() && it.length <= 5 }
    return fromName ?: "jpg"
  }
}
