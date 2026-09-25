package com.example.sms_remote

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sms_remote/sms")
            .setMethodCallHandler { call, result ->
                if (call.method != "compose") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val recipient = call.argument<String>("recipient")
                val text = call.argument<String>("text")
                if (recipient == null || !Regex("\\+?[0-9]{3,15}").matches(recipient)
                    || text.isNullOrBlank()) {
                    result.error("invalid_arguments", "Numero o testo non valido.", null)
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", recipient, null))
                    .putExtra("sms_body", text)
                try {
                    startActivity(intent)
                    // Il compositore Android non fornisce un esito di invio affidabile.
                    result.success("opened")
                } catch (_: ActivityNotFoundException) {
                    result.error("unavailable", "Nessuna app SMS disponibile.", null)
                } catch (_: SecurityException) {
                    result.error("unavailable", "Impossibile aprire l'app SMS.", null)
                }
            }
    }
}
