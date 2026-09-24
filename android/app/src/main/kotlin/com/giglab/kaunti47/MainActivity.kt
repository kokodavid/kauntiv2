package com.giglab.kaunti47

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // One-shot foreground location fix for the real map's opening camera
    // (ported from v1; never stored, no listener left running).
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.giglab.kaunti47/location",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "currentLocation" -> currentLocation(result)
        else -> result.notImplemented()
      }
    }
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

  private fun currentLocation(result: MethodChannel.Result) {
    if (!hasLocationPermission()) {
      result.success(null)
      return
    }

    val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    val provider = preferredProvider(locationManager)
    if (provider == null) {
      result.success(lastKnownLocation()?.toResultMap(source = "last-known"))
      return
    }

    val completed = AtomicBoolean(false)
    fun complete(location: Location?) {
      if (completed.compareAndSet(false, true)) {
        result.success(location?.toResultMap(source = "single-update"))
      }
    }

    lateinit var listener: LocationListener
    val timeout = Runnable {
      runCatching { locationManager.removeUpdates(listener) }
      complete(lastKnownLocation())
    }
    listener = object : LocationListener {
      override fun onLocationChanged(location: Location) {
        mainHandler.removeCallbacks(timeout)
        runCatching { locationManager.removeUpdates(this) }
        complete(location)
      }

      @Deprecated("Deprecated in Java")
      override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit

      override fun onProviderEnabled(provider: String) = Unit

      override fun onProviderDisabled(provider: String) = Unit
    }

    mainHandler.postDelayed(timeout, 5000)
    runCatching {
      locationManager.requestLocationUpdates(
        provider,
        0L,
        0f,
        listener,
        Looper.getMainLooper(),
      )
    }.onFailure {
      mainHandler.removeCallbacks(timeout)
      runCatching { locationManager.removeUpdates(listener) }
      complete(lastKnownLocation())
    }
  }

  private fun lastKnownLocation(): Location? {
    if (!hasLocationPermission()) return null

    val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    return locationManager.getProviders(true)
      .mapNotNull { provider -> runCatching { locationManager.getLastKnownLocation(provider) }.getOrNull() }
      .maxByOrNull { it.time }
  }

  private fun hasLocationPermission(): Boolean {
    val hasFine = ContextCompat.checkSelfPermission(
      this,
      Manifest.permission.ACCESS_FINE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED
    val hasCoarse = ContextCompat.checkSelfPermission(
      this,
      Manifest.permission.ACCESS_COARSE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED
    return hasFine || hasCoarse
  }

  private fun preferredProvider(locationManager: LocationManager): String? {
    val enabledProviders = locationManager.getProviders(true).toSet()
    return listOf(
      LocationManager.GPS_PROVIDER,
      LocationManager.NETWORK_PROVIDER,
      LocationManager.PASSIVE_PROVIDER,
    ).firstOrNull(enabledProviders::contains)
  }

  private fun Location.toResultMap(source: String) = mapOf(
    "latitude" to latitude,
    "longitude" to longitude,
    "time" to time,
    "provider" to "$provider/$source",
  )

  private companion object {
    const val TELEMETRY_DEFAULT_APPLIED = "telemetryDefaultApplied"
  }
}
