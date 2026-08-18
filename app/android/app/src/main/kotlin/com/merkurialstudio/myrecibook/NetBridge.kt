package com.merkurialstudio.myrecibook

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

// Fetches a shared recipe page over the platform HTTP stack (share-links
// spike). dart:io's HTTP parser dies on chunked trailers — Fastly sends a
// server-timing trailer on every Hearst recipe site — while the platform
// stack (OkHttp underneath) doesn't care. GET only, capped body, redirects
// followed manually so an http→https hop survives. Runs off the main thread;
// one request per call, no connection reuse worth optimizing here.
class NetBridge {
  private val io = Executors.newCachedThreadPool()
  private val main = Handler(Looper.getMainLooper())

  companion object {
    private const val CHANNEL = "com.merkurialstudio.myrecibook/net"
    private const val MAX_BODY = 10L * 1024 * 1024
    private const val MAX_REDIRECTS = 5
  }

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method != "get") {
        result.notImplemented()
        return@setMethodCallHandler
      }
      val url = call.argument<String>("url")
      val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
      if (url == null) {
        result.error("args", "missing url", null)
        return@setMethodCallHandler
      }
      io.execute {
        try {
          val out = fetch(url, headers)
          main.post { result.success(out) }
        } catch (e: Exception) {
          main.post { result.error("io", e.toString(), null) }
        }
      }
    }
  }

  private fun fetch(startUrl: String, headers: Map<String, String>): Map<String, Any> {
    var url = URL(startUrl)
    repeat(MAX_REDIRECTS + 1) {
      val conn = url.openConnection() as HttpURLConnection
      conn.requestMethod = "GET"
      conn.connectTimeout = 15_000
      conn.readTimeout = 20_000
      conn.instanceFollowRedirects = false
      for ((k, v) in headers) conn.setRequestProperty(k, v)
      try {
        val status = conn.responseCode
        if (status in 300..399) {
          val loc = conn.getHeaderField("Location")
            ?: throw IOException("redirect without location")
          url = URL(url, loc) // resolves relative redirects too
          return@repeat
        }
        // 4xx/5xx bodies come from errorStream; Dart maps the status itself.
        val stream = if (status >= 400) conn.errorStream else conn.inputStream
        val body = ByteArrayOutputStream()
        val buf = ByteArray(64 * 1024)
        var total = 0L
        stream?.use { s ->
          while (true) {
            val n = s.read(buf)
            if (n < 0) break
            total += n
            if (total > MAX_BODY) throw IOException("body over $MAX_BODY bytes")
            body.write(buf, 0, n)
          }
        }
        return mapOf("status" to status, "body" to body.toByteArray())
      } finally {
        conn.disconnect()
      }
    }
    throw IOException("too many redirects")
  }
}
