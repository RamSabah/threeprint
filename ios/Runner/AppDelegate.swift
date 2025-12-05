import UIKit
import Flutter
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase with try-catch for better error handling
    do {
      if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         FileManager.default.fileExists(atPath: path) {
        FirebaseApp.configure()
        print("Firebase configured successfully")
      } else {
        print("Warning: GoogleService-Info.plist not found at expected location")
      }
    } catch {
      print("Error configuring Firebase: \(error)")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
