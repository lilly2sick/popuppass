package com.popuppass.popup_pass

import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.HapticFeedbackConstants
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.popuppass/social")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareToStory") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val app = call.argument<String>("app")
                val path = call.argument<String>("path")
                if (app == null || path == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                val appId = call.argument<String>("appId")
                // Each app's "Add to Story" intent takes the image as a content://
                // URI and the Meta app id that is sharing.
                val action = when (app) {
                    "instagram" -> "com.instagram.share.ADD_TO_STORY"
                    "facebook" -> "com.facebook.stories.ADD_TO_STORY"
                    else -> null
                }
                val pkg = when (app) {
                    "instagram" -> "com.instagram.android"
                    "facebook" -> "com.facebook.katana"
                    else -> null
                }
                if (action == null || pkg == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                try {
                    // Reuses the FileProvider share_plus already declares; it only
                    // serves files under <cache>/share_plus/, where Create writes them.
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.flutter.share_provider",
                        File(path),
                    )
                    val intent = Intent(action).apply {
                        setDataAndType(uri, "image/png")
                        putExtra(
                            if (app == "instagram") "source_application"
                            else "com.facebook.platform.extra.APPLICATION_ID",
                            appId,
                        )
                        setPackage(pkg)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    if (intent.resolveActivity(packageManager) == null) {
                        result.success(false)
                    } else {
                        startActivity(intent)
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.success(false)
                }
            }
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
