package com.omegasub.omegasub_android

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingSave: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingFilename: String? = null
    private var pendingVideoFilename: String? = null
    private val folderRequest = 4917

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omegasub/storage")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveBesideVideo") { result.notImplemented(); return@setMethodCallHandler }
                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("filename")
                val videoFilename = call.argument<String>("videoFilename")
                if (bytes == null || filename.isNullOrBlank() || videoFilename.isNullOrBlank()) {
                    result.error("ARG", "Arquivo ou dados inválidos", null); return@setMethodCallHandler
                }
                if (pendingSave != null) { result.error("BUSY", "Autorização de pasta em andamento", null); return@setMethodCallHandler }
                val saved = getPreferences(MODE_PRIVATE).getString("video_folder_uri", null)
                if (saved != null) {
                    try {
                        val uri = Uri.parse(saved)
                        if (folderContainsVideo(uri, videoFilename)) {
                            saveInFolder(uri, filename, bytes)
                            result.success("saved")
                            return@setMethodCallHandler
                        }
                    } catch (_: Exception) { /* Solicita nova autorização */ }
                }
                pendingSave = result
                pendingBytes = bytes
                pendingFilename = filename
                pendingVideoFilename = videoFilename
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                }
                startActivityForResult(intent, folderRequest)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omegasub/python")
            .setMethodCallHandler { call, result ->
                if (call.method != "search" && call.method != "download") { result.notImplemented(); return@setMethodCallHandler }
                val arg = call.arguments as? String
                if (arg == null) { result.error("ARG", "Argumento inválido", null); return@setMethodCallHandler }
                executor.execute {
                    try {
                        if (!Python.isStarted()) Python.start(AndroidPlatform(applicationContext))
                        val module = Python.getInstance().getModule("omegasub_local")
                        val value = if (call.method == "search") module.callAttr("search", arg).toString()
                                    else module.callAttr("download", arg).toJava(ByteArray::class.java)
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("PYTHON", e.message ?: e.javaClass.simpleName, null) }
                    }
                }
            }
    }

    private fun folderContainsVideo(tree: Uri, videoFilename: String): Boolean {
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent))
        contentResolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) if (cursor.getString(0) == videoFilename) return true
        }
        return false
    }

    private fun saveInFolder(tree: Uri, filename: String, bytes: ByteArray) {
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent))
        var existing: Uri? = null
        contentResolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) if (cursor.getString(1) == filename) {
                existing = DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0)); break
            }
        }
        val target = existing ?: DocumentsContract.createDocument(contentResolver, parent, "application/x-subrip", filename)
            ?: throw IllegalStateException("Não foi possível criar a legenda nesta pasta")
        contentResolver.openOutputStream(target, "wt")?.use { it.write(bytes) }
            ?: throw IllegalStateException("Não foi possível gravar a legenda")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != folderRequest) return
        val callback = pendingSave ?: return
        try {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                callback.success("cancelled"); return
            }
            val uri = data.data!!
            val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            contentResolver.takePersistableUriPermission(uri, flags)
            val videoFilename = pendingVideoFilename!!
            if (!folderContainsVideo(uri, videoFilename)) {
                callback.error("WRONG_FOLDER", "A pasta selecionada não contém o vídeo $videoFilename. Escolha a pasta do vídeo.", null)
                return
            }
            saveInFolder(uri, pendingFilename!!, pendingBytes!!)
            getPreferences(MODE_PRIVATE).edit().putString("video_folder_uri", uri.toString()).apply()
            callback.success("saved")
        } catch (e: Exception) {
            callback.error("STORAGE", e.message ?: "Erro ao salvar legenda", null)
        } finally {
            pendingSave = null; pendingBytes = null; pendingFilename = null; pendingVideoFilename = null
        }
    }

    override fun onDestroy() { executor.shutdown(); super.onDestroy() }
}
