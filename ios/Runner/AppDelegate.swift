import Flutter
import UIKit
import GoogleMaps  // ← ДОБАВИТЬ ЭТУ СТРОКУ

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ДОБАВИТЬ: Инициализация Google Maps для iOS
    GMSServices.provideAPIKey("AIzaSyBL-JlBgfJIaL5aB3YTCd1J16qORChgOhg")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}