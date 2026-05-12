package com.example.conet_app

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
	private val downloadsChannel = "conet_app/downloads"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"saveToDownloads" -> {
						val fileName = call.argument<String>("fileName")
						val mimeType = call.argument<String>("mimeType")
						val bytes = call.argument<ByteArray>("bytes")

						if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
							result.error("INVALID_ARGS", "Missing fileName, mimeType, or bytes", null)
							return@setMethodCallHandler
						}

						try {
							val savedPathOrUri = saveToPublicDownloads(fileName, mimeType, bytes)
							result.success(savedPathOrUri)
						} catch (error: Exception) {
							result.error("SAVE_FAILED", error.message, null)
						}
					}

					"openDownloadedUri" -> {
						val uriString = call.argument<String>("uri")
						val mimeType = call.argument<String>("mimeType")

						if (uriString.isNullOrBlank()) {
							result.error("INVALID_ARGS", "Missing uri", null)
							return@setMethodCallHandler
						}

						try {
							openDownloadedUri(uriString, mimeType)
							result.success(true)
						} catch (error: Exception) {
							result.error("OPEN_FAILED", error.message, null)
						}
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun openDownloadedUri(uriString: String, mimeType: String?) {
		val uri = Uri.parse(uriString)
		val resolvedMimeType =
			if (mimeType.isNullOrBlank()) applicationContext.contentResolver.getType(uri) else mimeType
		val intent = Intent(Intent.ACTION_VIEW).apply {
			setDataAndType(uri, resolvedMimeType ?: "*/*")
			addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		startActivity(intent)
	}

	@Throws(IOException::class)
	private fun saveToPublicDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
		val cleanName = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_")

		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val resolver = applicationContext.contentResolver
			val values = ContentValues().apply {
				put(MediaStore.Downloads.DISPLAY_NAME, cleanName)
				put(MediaStore.Downloads.MIME_TYPE, mimeType)
				put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
				put(MediaStore.Downloads.IS_PENDING, 1)
			}

			val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
				?: throw IOException("Could not create download entry")

			resolver.openOutputStream(uri)?.use { output ->
				output.write(bytes)
			} ?: throw IOException("Could not open output stream")

			values.clear()
			values.put(MediaStore.Downloads.IS_PENDING, 0)
			resolver.update(uri, values, null, null)

			uri.toString()
		} else {
			val downloadsDirectory =
				Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
			if (!downloadsDirectory.exists()) {
				downloadsDirectory.mkdirs()
			}

			val file = File(downloadsDirectory, cleanName)
			FileOutputStream(file).use { stream ->
				stream.write(bytes)
				stream.flush()
			}

			MediaScannerConnection.scanFile(
				this,
				arrayOf(file.absolutePath),
				arrayOf(mimeType),
				null,
			)

			file.absolutePath
		}
	}
}
