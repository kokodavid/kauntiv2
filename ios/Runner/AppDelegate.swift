import Flutter
import CoreLocation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
