import UIKit
import Flutter
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure Firebase with error handling - moved after plugin registration
    DispatchQueue.main.async {
      self.configureFirebase()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureFirebase() {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          FileManager.default.fileExists(atPath: path) else {
      print("Warning: GoogleService-Info.plist not found. Firebase will not be configured.")
      return
    }
    
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("Firebase configured successfully")
    } else {
      print("Firebase already configured")
    }
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    // Handle background state
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    // Handle foreground state
  }
}
