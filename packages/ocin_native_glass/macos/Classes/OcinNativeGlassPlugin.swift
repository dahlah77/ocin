import Cocoa
import FlutterMacOS
import SwiftUI

public final class OcinNativeGlassPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(OcinGlassViewFactory(), withId: "ocin/native_glass_surface")
        let channel = FlutterMethodChannel(name: "ocin/native_glass", binaryMessenger: registrar.messenger)
        let instance = OcinNativeGlassPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "available":
            if #available(macOS 26.0, *) {
                result(!NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency)
            } else {
                result(false)
            }
        case "reduceTransparency":
            result(NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private final class OcinGlassViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let hosted = NSHostingView(rootView: OcinSwiftUIGlassBackground())
        hosted.frame = NSRect(x: 0, y: 0, width: 320, height: 70)
        return hosted
    }
}

private struct OcinSwiftUIGlassBackground: View {
    var body: some View {
        Group {
            if #available(macOS 26.0, *) {
                GlassEffectContainer {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.20))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
