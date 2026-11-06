import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    Self.excludeSandboxFromCloudBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Vault, Hollow, Four Gates, and generated PDFs stay on-device.
  /// iCloud Backup must not lift the sandbox.
  static func excludeSandboxFromCloudBackup() {
    let fileManager = FileManager.default
    let roots: [FileManager.SearchPathDirectory] = [
      .documentDirectory,
      .libraryDirectory,
      .applicationSupportDirectory,
      .cachesDirectory,
    ]
    for directory in roots {
      guard let url = fileManager.urls(for: directory, in: .userDomainMask).first else {
        continue
      }
      excludeFromBackup(url)
    }
  }

  static func excludeFromBackup(_ url: URL) {
    var mutable = url
    do {
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try mutable.setResourceValues(values)
    } catch {
      NSLog("Aegis: failed to exclude %@ from backup: %@", url.path, error.localizedDescription)
    }
  }
}
