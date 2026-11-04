package com.popuppass.popup_pass

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.popuppass/haptics")
            .setMethodCallHandler { call, result ->
                if (call.method != "notify") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val type = call.argument<String>("type")
                val view = window.decorView
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // CONFIRM / REJECT exist from API 30.
                    val constant = when (type) {
                        "success" -> HapticFeedbackConstants.CONFIRM
                        "warning", "error" -> HapticFeedbackConstants.REJECT
                        else -> null
                    }
                    if (constant == null) {
                        result.success(false)
                    } else {
                        view.performHapticFeedback(constant)
                        result.success(true)
                    }
                } else {
                    // Fallback vibration for older devices.
                    @Suppress("DEPRECATION")
                    val vibrator = getSystemService(VIBRATOR_SERVICE) as? Vibrator
                    val ms = if (type == "success") 30L else 60L
                    if (vibrator == null || !vibrator.hasVibrator()) {
                        result.success(false)
                    } else {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            vibrator.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(ms)
                        }
                        result.success(true)
                    }
                }
            }
    }
}
