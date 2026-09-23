package com.example.keemo

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.jeeny.autoaccept/native_bridge"
    private val PREFS_NAME = "JeenyAutoAcceptPrefs"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getManufacturer" -> {
                        result.success(
                            mapOf(
                                "manufacturer" to Build.MANUFACTURER.orEmpty(),
                                "brand" to Build.BRAND.orEmpty(),
                                "model" to Build.MODEL.orEmpty(),
                                "sdk" to Build.VERSION.SDK_INT
                            )
                        )
                    }
                    "getAndroidId" -> {
                        // Settings.Secure.ANDROID_ID: unique per physical device+app-install
                        // combo since Android 8. Only resets on factory reset. This is the
                        // proper device fingerprint — device_info_plus's `id` field returns
                        // Build.ID (OS build number) which is NOT device-unique.
                        val androidId = try {
                            Settings.Secure.getString(
                                contentResolver,
                                Settings.Secure.ANDROID_ID
                            ).orEmpty()
                        } catch (_: Exception) {
                            ""
                        }
                        result.success(androidId)
                    }
                    "setBubbleEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit()
                            .putBoolean("bubble_enabled", enabled)
                            .apply()
                        // Kick the running accessibility service to refresh its overlay.
                        JeenyAccessibilityService.refreshOverlay(this)
                        result.success(true)
                    }
                    "isBubbleEnabled" -> {
                        result.success(
                            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                                .getBoolean("bubble_enabled", false)
                        )
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(
                            isAccessibilityServiceEnabled(
                                context,
                                JeenyAccessibilityService::class.java
                            )
                        )
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettingsSmart()
                        result.success(true)
                    }
                    "isOverlayPermissionGranted" -> {
                        result.success(Settings.canDrawOverlays(context))
                    }
                    "openOverlaySettings" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestBatteryOptimizationExemption" -> {
                        result.success(requestBatteryOptimizationExemption())
                    }
                    "openAutoStartSettings" -> {
                        result.success(openAutoStartSettings())
                    }
                    "getAutoAcceptEnabled" -> {
                        result.success(
                            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                                .getBoolean("is_enabled", false)
                        )
                    }
                    "getSavedCriteria" -> {
                        // Return the saved criteria so Flutter can restore
                        // slider positions on cold app start.
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        result.success(
                            mapOf(
                                "is_enabled" to prefs.getBoolean("is_enabled", false),
                                "min_fare" to prefs.getFloat("min_fare", 5.0f).toDouble(),
                                "max_pickup_mins" to prefs.getInt("max_pickup_mins", 5)
                            )
                        )
                    }
                    "updateCriteria" -> {
                        val isEnabled = call.argument<Boolean>("is_enabled") ?: false
                        val minFare = call.argument<Double>("min_fare") ?: 5.0
                        val maxPickupMins = call.argument<Int>("max_pickup_mins") ?: 5

                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit()
                            .putBoolean("is_enabled", isEnabled)
                            .putFloat("min_fare", minFare.toFloat())
                            .putInt("max_pickup_mins", maxPickupMins)
                            .apply()

                        result.success(true)
                    }
                    "drainPendingOrders" -> {
                        // Atomic read-and-clear so the Dashboard can push
                        // pending accepted orders into Supabase's
                        // accepted_orders_log without racing the service.
                        val p = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val json = p.getString("pending_orders", "[]") ?: "[]"
                        p.edit().remove("pending_orders").commit()
                        result.success(json)
                    }
                    "getLastAcceptedOrder" -> {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val fare = prefs.getString("last_accepted_fare", null)
                        val time = prefs.getString("last_accepted_time", null)
                        val timestamp = prefs.getLong("last_accepted_timestamp", 0)
                        if (fare != null && time != null) {
                            result.success(
                                mapOf(
                                    "fare" to fare,
                                    "time" to time,
                                    "timestamp" to timestamp
                                )
                            )
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(context: Context, service: Class<*>): Boolean {
        val expected = "${context.packageName}/${service.name}"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }

    private fun openAccessibilitySettingsSmart() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val candidates = mutableListOf<Intent>()

        when {
            manufacturer.contains("samsung") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.android.settings",
                        "com.android.settings.Settings\$AccessibilityInstalledServiceActivity"
                    )
                )
            }
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.android.settings",
                        "com.android.settings.Settings\$AccessibilitySettingsActivity"
                    )
                )
            }
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.android.settings",
                        "com.android.settings.Settings\$AccessibilitySettingsActivity"
                    )
                )
            }
        }
        candidates += Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)

        launchFirstResolvable(candidates)
    }

    @SuppressLint("BatteryLife")
    private fun requestBatteryOptimizationExemption(): Boolean {
        return try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (pm.isIgnoringBatteryOptimizations(packageName)) return true

            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:$packageName"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            try {
                startActivity(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun openAutoStartSettings(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val candidates = mutableListOf<Intent>()

        when {
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                )
            }
            manufacturer.contains("oppo") || manufacturer.contains("realme") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                    )
                )
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.oppo.safe",
                        "com.oppo.safe.permission.startup.StartupAppListActivity"
                    )
                )
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.startupapp.StartupAppListActivity"
                    )
                )
            }
            manufacturer.contains("vivo") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
                    )
                )
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                    )
                )
            }
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                )
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.optimize.process.ProtectActivity"
                    )
                )
            }
            manufacturer.contains("samsung") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.ui.battery.BatteryActivity"
                    )
                )
            }
            manufacturer.contains("letv") -> {
                candidates += Intent().setComponent(
                    ComponentName(
                        "com.letv.android.letvsafe",
                        "com.letv.android.letvsafe.AutobootManageActivity"
                    )
                )
            }
        }
        // Fallback -> app details settings
        candidates += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:$packageName"))

        return launchFirstResolvable(candidates)
    }

    private fun launchFirstResolvable(candidates: List<Intent>): Boolean {
        for (raw in candidates) {
            val intent = raw.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                try {
                    startActivity(intent)
                    return true
                } catch (_: Exception) {
                    // try next
                }
            }
        }
        return false
    }
}
