package com.gostory.gostory

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val history = getSharedPreferences("permission_requests", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gostory/permissions")
            .setMethodCallHandler { call, result ->
                val name = call.arguments as? String
                val permissions = when (name) {
                    "camera" -> listOf(Manifest.permission.CAMERA)
                    "location" -> listOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
                    else -> { result.notImplemented(); return@setMethodCallHandler }
                }
                when (call.method) {
                    "markRequested" -> { history.edit().putBoolean(name, true).apply(); result.success(null) }
                    "status" -> {
                        val granted = Build.VERSION.SDK_INT < 23 || permissions.any {
                            checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
                        }
                        val blocked = !granted && history.getBoolean(name, false) &&
                            permissions.none { shouldShowRequestPermissionRationale(it) }
                        result.success(if (granted) "granted" else if (blocked) "blocked" else "denied")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
