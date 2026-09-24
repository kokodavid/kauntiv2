import Flutter
import CoreLocation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var currentLocationRequests: [IosCurrentLocationRequest] = []
  private var locationAuthorizationRequests: [IosLocationAuthorizationRequest] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    applyMapboxTelemetryDefault()
    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let registrar = self.registrar(forPlugin: "Kaunti47LocationPlugin") {
      FlutterMethodChannel(
        name: "com.giglab.kaunti47/location",
        binaryMessenger: registrar.messenger()
      ).setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "currentLocation":
          self?.currentLocation(result: result)
        case "locationAuthorizationStatus":
          self?.locationAuthorizationStatus(result: result)
        case "requestAlwaysLocationAuthorization":
          self?.requestAlwaysLocationAuthorization(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return didLaunch
  }

  /// Turns Mapbox location telemetry off once, before any map exists (doc 05:
  /// precise location stays on the device). MapboxMaps' EventsManager and its
  /// (i) attribution menu both read this key, so a user who opts back in from
  /// that menu keeps their choice on later launches.
  private func applyMapboxTelemetryDefault() {
    let defaults = UserDefaults.standard
    let appliedKey = "kaunti47.mapboxTelemetryDefaultApplied"
    guard !defaults.bool(forKey: appliedKey) else { return }
    defaults.set(false, forKey: "MGLMapboxMetricsEnabled")
    defaults.set(true, forKey: appliedKey)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// One-shot foreground fix (~5 s budget), never stored: ported from v1.
  private func currentLocation(result: @escaping FlutterResult) {
    let request = IosCurrentLocationRequest(
      result: result,
      onFinish: { [weak self] finishedRequest in
        self?.currentLocationRequests.removeAll { $0 === finishedRequest }
      }
    )
    currentLocationRequests.append(request)
    request.start()
  }

  private func locationAuthorizationStatus(result: FlutterResult) {
    let manager = CLLocationManager()
    result(manager.authorizationStatus.toResultString())
  }

  private func requestAlwaysLocationAuthorization(result: @escaping FlutterResult) {
    let request = IosLocationAuthorizationRequest(
      result: result,
      onFinish: { [weak self] finishedRequest in
        self?.locationAuthorizationRequests.removeAll { $0 === finishedRequest }
      }
    )
    locationAuthorizationRequests.append(request)
    request.start()
  }
}

private final class IosLocationAuthorizationRequest: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var result: FlutterResult?
  private let onFinish: (IosLocationAuthorizationRequest) -> Void

  init(
    result: @escaping FlutterResult,
    onFinish: @escaping (IosLocationAuthorizationRequest) -> Void
  ) {
    self.result = result
    self.onFinish = onFinish
    super.init()
    manager.delegate = self
  }

  func start() {
    guard CLLocationManager.locationServicesEnabled() else {
      complete(with: "denied")
      return
    }

    switch manager.authorizationStatus {
    case .authorizedAlways:
      complete(with: manager.authorizationStatus.toResultString())
    case .notDetermined, .authorizedWhenInUse:
      manager.requestAlwaysAuthorization()
    case .denied, .restricted:
      complete(with: manager.authorizationStatus.toResultString())
    @unknown default:
      complete(with: "denied")
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .notDetermined:
      break
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
      complete(with: manager.authorizationStatus.toResultString())
    @unknown default:
      complete(with: "denied")
    }
  }

  private func complete(with status: String) {
    guard let result else { return }
    self.result = nil
    manager.delegate = nil
    result(status)
    onFinish(self)
  }
}

private final class IosCurrentLocationRequest: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var result: FlutterResult?
  private let onFinish: (IosCurrentLocationRequest) -> Void
  private var timeoutWorkItem: DispatchWorkItem?

  init(
    result: @escaping FlutterResult,
    onFinish: @escaping (IosCurrentLocationRequest) -> Void
  ) {
    self.result = result
    self.onFinish = onFinish
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func start() {
    guard CLLocationManager.locationServicesEnabled() else {
      complete(with: nil)
      return
    }

    let status = manager.authorizationStatus
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      requestCurrentLocation()
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      complete(with: nil)
    @unknown default:
      complete(with: nil)
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      requestCurrentLocation()
    case .denied, .restricted:
      complete(with: nil)
    case .notDetermined:
      break
    @unknown default:
      complete(with: nil)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    complete(with: locations.last ?? manager.location)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    complete(with: manager.location)
  }

  private func requestCurrentLocation() {
    timeoutWorkItem?.cancel()

    // 5s, matching Android's `currentLocation()` window (MainActivity.kt)
    // -- this was 2.5s, which is tight enough on real hardware (as
    // opposed to a simulator, which resolves a mocked fix instantly)
    // that a genuine first/cold GPS fix routinely missed it, especially
    // indoors, so `manager.location` at timeout was still nil: distance
    // labels (`_placeDistanceLabel`, which has no fallback by design --
    // see `supabase_discover_repository.dart`) then have nothing to show
    // even though nothing was actually broken, just slow. Unlike
    // Android's fallback, `manager.location` on timeout here is *not* a
    // guaranteed cached last-known fix -- it's only populated once this
    // same `CLLocationManager` instance has itself received an update --
    // so widening the window is what actually gives a real fix a chance
    // to land, not a fallback path.
    let timeout = DispatchWorkItem { [weak self] in
      guard let self else { return }
      complete(with: manager.location)
    }
    timeoutWorkItem = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timeout)
    manager.requestLocation()
  }

  private func complete(with location: CLLocation?) {
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil

    guard let result else { return }
    self.result = nil
    manager.delegate = nil
    result(location?.toResultMap())
    onFinish(self)
  }
}

private extension CLLocation {
  func toResultMap() -> [String: Any] {
    [
      "latitude": coordinate.latitude,
      "longitude": coordinate.longitude,
      "time": Int(timestamp.timeIntervalSince1970 * 1000),
      "provider": "ios-core-location",
    ]
  }
}

private extension CLAuthorizationStatus {
  func toResultString() -> String {
    switch self {
    case .authorizedAlways:
      return "authorizedAlways"
    case .authorizedWhenInUse:
      return "authorizedWhenInUse"
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    @unknown default:
      return "denied"
    }
  }
}
