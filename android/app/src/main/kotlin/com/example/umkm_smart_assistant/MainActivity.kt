package com.example.umkm_smart_assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine  // Tambahkan impor ini
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.umkm_smart_assistant/save_to_gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImage") {
                val args = call.arguments as Map<String, Any>
                val data = args["_data"] as ByteArray
                val relativePath = args["relative_path"] as String
                val title = args["title"] as String
                val mimeType = args["mime_type"] as String

                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, title)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
                    }
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                uri?.let {
                    contentResolver.openOutputStream(it)?.use { outputStream ->
                        outputStream.write(data)
                    }
                    values.clear()
                    values.put(MediaStore.Images.Media.IS_PENDING, 0)
                    contentResolver.update(it, values, null, null)
                    result.success(true)
                } ?: result.success(false)
            } else if (call.method == "scanFile") {
                // Untuk Android 9 ke bawah, kita bisa skip karena MediaScanner tidak diperlukan
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}