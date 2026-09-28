package com.example.sms_remote

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private data class SmsRequest(
        val id: Int,
        val recipient: String,
        val text: String,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val CHANNEL = "sms_remote/sms"
        private const val SMS_PERMISSION_REQUEST = 4182
        private const val SMS_SENT_ACTION = "com.example.sms_remote.SMS_SENT"
        private const val EXTRA_REQUEST_ID = "request_id"
        private const val SEND_TIMEOUT_MILLIS = 60_000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var nextRequestId = 0
    private var pendingRequest: SmsRequest? = null
    private var pendingParts = 0
    private var failedPart = false
    private var receiverRegistered = false

    private val sendTimeout = Runnable {
        finishWithError(
            "send_timeout",
            "Android non ha restituito l'esito dell'invio.",
        )
    }

    private val smsSentReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val request = pendingRequest ?: return
            if (intent?.getIntExtra(EXTRA_REQUEST_ID, -1) != request.id) return

            if (resultCode != Activity.RESULT_OK) failedPart = true
            pendingParts -= 1
            if (pendingParts == 0) {
                if (failedPart) {
                    finishWithError("send_failed", "Android non ha inviato l'SMS.")
                } else {
                    finishWithSuccess("sent")
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerSmsSentReceiver()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "send") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingRequest != null) {
                    result.error("busy", "È già in corso un invio SMS.", null)
                    return@setMethodCallHandler
                }

                val recipient = call.argument<String>("recipient")
                val text = call.argument<String>("text")
                if (recipient == null || !Regex("\\+?[0-9]{3,15}").matches(recipient)
                    || text.isNullOrBlank()) {
                    result.error("invalid_arguments", "Numero o testo non valido.", null)
                    return@setMethodCallHandler
                }
                // The messaging-specific feature was introduced in Android 13.
                // Older phones only advertise the general telephony feature.
                val smsFeature = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    PackageManager.FEATURE_TELEPHONY_MESSAGING
                } else {
                    PackageManager.FEATURE_TELEPHONY
                }
                if (!packageManager.hasSystemFeature(smsFeature)) {
                    result.error("unavailable", "Questo dispositivo non supporta gli SMS.", null)
                    return@setMethodCallHandler
                }

                val request = SmsRequest(++nextRequestId, recipient, text, result)
                pendingRequest = request
                if (checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                    sendSms(request)
                } else {
                    requestPermissions(
                        arrayOf(Manifest.permission.SEND_SMS),
                        SMS_PERMISSION_REQUEST,
                    )
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST) return

        val request = pendingRequest ?: return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            sendSms(request)
        } else {
            finishWithError("permission_denied", "Permesso di invio SMS negato.")
        }
    }

    private fun sendSms(request: SmsRequest) {
        try {
            val subscriptionId = SmsManager.getDefaultSmsSubscriptionId()
            if (subscriptionId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                finishWithError(
                    "sim_not_selected",
                    "Seleziona una SIM predefinita per gli SMS nelle impostazioni Android.",
                )
                return
            }

            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
                    .createForSubscriptionId(subscriptionId)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
            }
            val parts = smsManager.divideMessage(request.text)
            if (parts.isEmpty()) {
                finishWithError("send_failed", "Il testo SMS è vuoto.")
                return
            }

            pendingParts = parts.size
            failedPart = false
            mainHandler.removeCallbacks(sendTimeout)
            mainHandler.postDelayed(sendTimeout, SEND_TIMEOUT_MILLIS)

            val sentIntents = ArrayList<PendingIntent>(parts.size)
            for (index in parts.indices) {
                val sentIntent = Intent(SMS_SENT_ACTION)
                    .setPackage(packageName)
                    .setData(Uri.parse("smsremote://sent/${request.id}/$index"))
                    .putExtra(EXTRA_REQUEST_ID, request.id)
                sentIntents += PendingIntent.getBroadcast(
                    this,
                    index,
                    sentIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }

            if (parts.size == 1) {
                smsManager.sendTextMessage(
                    request.recipient,
                    null,
                    parts.first(),
                    sentIntents.first(),
                    null,
                )
            } else {
                smsManager.sendMultipartTextMessage(
                    request.recipient,
                    null,
                    parts,
                    sentIntents,
                    null,
                )
            }
        } catch (_: SecurityException) {
            finishWithError("permission_denied", "Permesso di invio SMS negato.")
        } catch (_: UnsupportedOperationException) {
            finishWithError("unavailable", "Questo dispositivo non supporta gli SMS.")
        } catch (_: Exception) {
            finishWithError("send_failed", "Android non è riuscito ad avviare l'invio.")
        }
    }

    private fun registerSmsSentReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter(SMS_SENT_ACTION).apply {
            addDataScheme("smsremote")
        }
        ContextCompat.registerReceiver(
            this,
            smsSentReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        receiverRegistered = true
    }

    private fun finishWithSuccess(value: String) {
        val result = pendingRequest?.result ?: return
        clearPendingRequest()
        result.success(value)
    }

    private fun finishWithError(code: String, message: String) {
        val result = pendingRequest?.result ?: return
        clearPendingRequest()
        result.error(code, message, null)
    }

    private fun clearPendingRequest() {
        mainHandler.removeCallbacks(sendTimeout)
        pendingRequest = null
        pendingParts = 0
        failedPart = false
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            unregisterReceiver(smsSentReceiver)
            receiverRegistered = false
        }
        super.onDestroy()
    }
}
