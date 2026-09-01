import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = self.registrar(forPlugin: "AegisSovereignty") {
      let channel = FlutterMethodChannel(
        name: "com.zwischenzug.aegis/sovereignty",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "sealFromBackup" {
          AegisSovereignty.sealFromBackup()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    AegisSovereignty.sealFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Marks Aegis on-device stores as ineligible for iCloud / Finder backup.
/// Re-applied on every launch because new files do not inherit the flag.
enum AegisSovereignty {
  static func sealFromBackup() {
    let fm = FileManager.default
    var roots: [URL] = []
    roots.append(contentsOf: fm.urls(for: .documentDirectory, in: .userDomainMask))
    roots.append(contentsOf: fm.urls(for: .applicationSupportDirectory, in: .userDomainMask))
    if let library = fm.urls(for: .libraryDirectory, in: .userDomainMask).first {
      roots.append(library.appendingPathComponent("Preferences", isDirectory: true))
    }
    for root in roots {
      exclude(root)
      guard let enumerator = fm.enumerator(
        at: root,
        includingPropertiesForKeys: [.isExcludedFromBackupKey],
        options: [.skipsHiddenFiles]
      ) else { continue }
      for case let fileURL as URL in enumerator {
        exclude(fileURL)
      }
    }
  }

  private static func exclude(_ url: URL) {
    var dest = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? dest.setResourceValues(values)
  }
}
