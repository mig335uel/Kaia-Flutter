import Flutter
import UIKit
import CryptoKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if !DEBUG
      AgoraASMShield.activarAntiDebugger()
    #else
      NSLog("Bunker desactivado para desarrollo")
    #endif
      
      if(AgoraASMShield.isEnvironmentCompromised()){
          AgoraASMShield.asldkfjañlsd()
      }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
