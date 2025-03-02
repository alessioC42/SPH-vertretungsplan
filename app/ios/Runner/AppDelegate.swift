import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController;
      let utilsChannel = FlutterMethodChannel(name: "io.github.lanis-mobile/utils", binaryMessenger: controller.binaryMessenger);
      let storageChannel = FlutterMethodChannel(name: "io.github.lanis-mobile/storage", binaryMessenger: controller.binaryMessenger);

      utilsChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          if (call.method == "showToastShort") {
          } else {
              result(FlutterMethodNotImplemented)
          }
      });
      
      storageChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          if (call.method == "takePhoto") {
              self.takePhotoCall(result: result)
          } else {
              result(FlutterMethodNotImplemented)
          }
      });
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func takePhotoCall(result: FlutterResult) {
        
    }
}
