package com.merkurialstudio.myrecibook

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.Executors

// Stateless per-call SAF wrapper — Dart owns all caching and layout (arch §4).
// Every listing is ONE child-documents query; per-file lookups are banned
// (SAF listFiles is one Binder IPC per file). Lost grant surfaces as
// GRANT_LOST for the re-pick flow, never a crash (arch §7).
class SafBridge(private val activity: Activity) {
  private val io = Executors.newSingleThreadExecutor()
  private val main = Handler(Looper.getMainLooper())
  private var pendingPick: MethodChannel.Result? = null

  companion object {
    private const val CHANNEL = "com.merkurialstudio.myrecibook/saf"
    private const val PICK_REQUEST = 0x5AF1
    private const val PERSIST_FLAGS =
      Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
  }

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "pickFolder" -> pickFolder(result)
        "hasGrant" -> runIo(result, null) {
          hasGrant(Uri.parse(requireArg(call.argument("uri"))))
        }
        "listChildren" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            listChildren(Uri.parse(requireArg(tree)), call.argument("parentDocId"))
          }
        }
        "readFile" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            readFile(Uri.parse(requireArg(tree)), requireArg(call.argument("docId")))
          }
        }
        "readChildFiles" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            readChildFiles(
              Uri.parse(requireArg(tree)),
              call.argument("parentDocId"),
              requireArg(call.argument("suffix")),
            )
          }
        }
        "createFile" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            createFile(
              Uri.parse(requireArg(tree)),
              requireArg(call.argument("parentDocId")),
              requireArg(call.argument("name")),
              requireArg(call.argument("mime")),
            )
          }
        }
        "writeFile" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            writeFile(
              Uri.parse(requireArg(tree)),
              requireArg(call.argument("docId")),
              requireArg(call.argument("bytes")),
            )
          }
        }
        "createDir" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            createDir(Uri.parse(requireArg(tree)), requireArg(call.argument("name")))
          }
        }
        "deleteFile" -> {
          val tree = call.argument<String>("treeUri")
          runIo(result, tree) {
            deleteFile(Uri.parse(requireArg(tree)), requireArg(call.argument("docId")))
          }
        }
        "releaseGrant" -> runIo(result, null) {
          releaseGrant(Uri.parse(requireArg(call.argument("uri"))))
        }
        else -> result.notImplemented()
      }
    }
  }

  // treeUri (when known) lets the error path tell a dead grant from plain IO
  // failure: FileNotFoundException on a vanished tree must branch to re-pick.
  private fun runIo(result: MethodChannel.Result, treeUri: String?, op: () -> Any?) {
    io.execute {
      try {
        val value = op()
        main.post { result.success(value) }
      } catch (e: Exception) {
        val code = when {
          e is SecurityException -> "GRANT_LOST"
          treeUri != null && !grantAlive(Uri.parse(treeUri)) -> "GRANT_LOST"
          else -> "SAF_IO"
        }
        main.post { result.error(code, e.message ?: e.javaClass.simpleName, null) }
      }
    }
  }

  private fun <T> requireArg(value: T?): T =
    value ?: throw IllegalArgumentException("missing argument")

  private fun pickFolder(result: MethodChannel.Result) {
    pendingPick?.success(null) // superseded pick resolves as cancel
    pendingPick = result
    try {
      activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), PICK_REQUEST)
    } catch (e: Exception) {
      pendingPick = null
      result.error("SAF_IO", e.message, null)
    }
  }

  fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != PICK_REQUEST) return false
    val reply = pendingPick ?: return true
    pendingPick = null
    val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
    if (uri == null) {
      reply.success(null)
      return true
    }
    try {
      activity.contentResolver.takePersistableUriPermission(uri, PERSIST_FLAGS)
      reply.success(uri.toString())
    } catch (e: Exception) {
      reply.error("SAF_IO", e.message, null)
    }
    return true
  }

  private fun hasGrant(uri: Uri): Boolean {
    val held = activity.contentResolver.persistedUriPermissions.any {
      it.uri == uri && it.isReadPermission && it.isWritePermission
    }
    return held && grantAlive(uri)
  }

  // Existence probe: the grant may be held while the folder itself is gone.
  private fun grantAlive(treeUri: Uri): Boolean =
    try {
      val docUri = DocumentsContract.buildDocumentUriUsingTree(
        treeUri, DocumentsContract.getTreeDocumentId(treeUri)
      )
      activity.contentResolver.query(
        docUri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID), null, null, null
      )?.use { it.moveToFirst() } ?: false
    } catch (_: Exception) {
      false
    }

  private fun listChildren(treeUri: Uri, parentDocId: String?): List<Map<String, Any>> {
    val dirDocId = parentDocId ?: DocumentsContract.getTreeDocumentId(treeUri)
    val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, dirDocId)
    val projection = arrayOf(
      DocumentsContract.Document.COLUMN_DOCUMENT_ID,
      DocumentsContract.Document.COLUMN_DISPLAY_NAME,
      DocumentsContract.Document.COLUMN_MIME_TYPE,
    )
    val rows = mutableListOf<Map<String, Any>>()
    activity.contentResolver.query(childrenUri, projection, null, null, null)?.use { c ->
      while (c.moveToNext()) {
        val docId = c.getString(0) ?: continue
        val mime = c.getString(2) ?: ""
        rows.add(
          mapOf(
            "docId" to docId,
            "name" to (c.getString(1) ?: ""),
            "mime" to mime,
            "isDir" to (mime == DocumentsContract.Document.MIME_TYPE_DIR),
          )
        )
      }
    } ?: throw FileNotFoundException("child query failed: $dirDocId")
    return rows
  }

  private fun readFile(treeUri: Uri, docId: String): ByteArray {
    val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
    return activity.contentResolver.openInputStream(uri)?.use { it.readBytes() }
      ?: throw FileNotFoundException(docId)
  }

  // Whole-directory read in ONE channel round trip: list once, then read every
  // child file whose name ends with [suffix] inside this executor call — the
  // per-file channel hop is what a cold scan must never pay per document. An
  // unreadable child is left out of the map (Dart counts the gap as skipped);
  // SecurityException still escapes so runIo reports GRANT_LOST, same as
  // readFile.
  private fun readChildFiles(
    treeUri: Uri,
    parentDocId: String?,
    suffix: String,
  ): Map<String, ByteArray> {
    val files = mutableMapOf<String, ByteArray>()
    for (row in listChildren(treeUri, parentDocId)) {
      if (row["isDir"] == true) continue
      val name = row["name"] as String
      if (!name.endsWith(suffix)) continue
      try {
        files[name] = readFile(treeUri, row["docId"] as String)
      } catch (e: SecurityException) {
        throw e
      } catch (e: Exception) {
        // Unreadable child: omitted, never fatal for the batch — unless the
        // whole tree died mid-scan, which must branch to re-pick exactly as a
        // single readFile would via runIo's grantAlive fallback.
        if (!grantAlive(treeUri)) throw SecurityException(e.message)
      }
    }
    return files
  }

  private fun createFile(treeUri: Uri, parentDocId: String, name: String, mime: String): String {
    val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, parentDocId)
    val created = DocumentsContract.createDocument(activity.contentResolver, parentUri, mime, name)
      ?: throw FileNotFoundException("createDocument failed: $name")
    return DocumentsContract.getDocumentId(created)
  }

  private fun writeFile(treeUri: Uri, docId: String, bytes: ByteArray): Any? {
    val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
    activity.contentResolver.openOutputStream(uri, "wt")?.use {
      it.write(bytes)
      it.flush()
    } ?: throw FileNotFoundException(docId)
    return null
  }

  private fun createDir(treeUri: Uri, name: String): String =
    createFile(
      treeUri,
      DocumentsContract.getTreeDocumentId(treeUri),
      name,
      DocumentsContract.Document.MIME_TYPE_DIR,
    )

  private fun deleteFile(treeUri: Uri, docId: String): Boolean =
    try {
      DocumentsContract.deleteDocument(
        activity.contentResolver,
        DocumentsContract.buildDocumentUriUsingTree(treeUri, docId),
      )
    } catch (_: Exception) {
      false
    }

  private fun releaseGrant(uri: Uri): Any? {
    try {
      activity.contentResolver.releasePersistableUriPermission(uri, PERSIST_FLAGS)
    } catch (_: Exception) {
      // re-pick hygiene: releasing an already-dead grant is a no-op
    }
    return null
  }
}
