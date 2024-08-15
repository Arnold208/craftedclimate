import UIKit
import Flutter
import GoogleMaps
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     FirebaseApp.configure()
       GMSServices.provideAPIKey("AIzaSyD48PVvwczR-cT2dsJ3qxrGWiASf42OSSs")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
