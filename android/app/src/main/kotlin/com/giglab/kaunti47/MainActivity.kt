package com.giglab.kaunti47

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.giglab.kaunti47/mapbox",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "applyTelemetryDefault" -> result.success(applyMapboxTelemetryDefault())
        else -> result.notImplemented()
      }
    }
  }

  /**
   * Turns Mapbox location telemetry off once, on the first real-map launch
   * (doc 05: precise location stays on the device). After that the user's
   * own choice in the map's (i) attribution menu is left alone.
   *
   * Called from Dart after a map exists, so Mapbox Common's native library
   * is loaded. Reflection keeps the app module from depending directly on
   * Mapbox Common's version.
   */
  private fun applyMapboxTelemetryDefault(): Boolean {
    val prefs = getSharedPreferences("kaunti47_mapbox", Context.MODE_PRIVATE)
    if (prefs.getBoolean(TELEMETRY_DEFAULT_APPLIED, false)) return true
    return try {
      val telemetryUtils = Class.forName("com.mapbox.common.TelemetryUtils")
      val setState = telemetryUtils.methods.first {
        it.name == "setEventsCollectionState" && it.parameterTypes.size == 2
      }
      setState.invoke(null, false, null)
      prefs.edit().putBoolean(TELEMETRY_DEFAULT_APPLIED, true).apply()
      true
    } catch (error: Throwable) {
      Log.w("Kaunti47", "Could not turn off Mapbox telemetry", error)
      false
    }
  }

  private companion object {
    const val TELEMETRY_DEFAULT_APPLIED = "telemetryDefaultApplied"
  }
}
