package com.merkurialstudio.myrecibook

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private val shareBridge = ShareBridge(this)
  private val safBridge = SafBridge(this)
  private val authBridge = AuthBridge(this)

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    shareBridge.attach(messenger)
    safBridge.attach(messenger)
    authBridge.attach(messenger)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Recreation and recents relaunch redeliver the original intent;
    // re-processing it would duplicate an already-handled share/redirect.
    if (savedInstanceState == null && !fromHistory(intent)) {
      route(intent)
    }
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    if (!fromHistory(intent)) route(intent)
  }

  // The oauth2 redirect goes to AuthBridge, never ShareBridge.
  private fun route(intent: Intent?) {
    if (authBridge.handleIntent(intent)) return
    shareBridge.handleIntent(intent)
  }

  private fun fromHistory(intent: Intent?): Boolean =
    intent != null &&
      (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    if (safBridge.handleActivityResult(requestCode, resultCode, data)) return
    super.onActivityResult(requestCode, resultCode, data)
  }
}
