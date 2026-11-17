import Flutter
import SwiftUI
import UIKit

public final class OcinNativeGlassPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(OcinGlassViewFactory(), withId: "ocin/native_glass_surface")
        let channel = FlutterMethodChannel(name: "ocin/native_glass", binaryMessenger: registrar.messenger())
        let instance = OcinNativeGlassPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "available":
            if #available(iOS 26.0, *) {
                result(!UIAccessibility.isReduceTransparencyEnabled)
            } else {
                result(false)
            }
        case "reduceTransparency":
            result(UIAccessibility.isReduceTransparencyEnabled)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private final class OcinGlassViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        OcinNativeGlassView(frame: frame)
    }
}

private final class OcinNativeGlassView: NSObject, FlutterPlatformView {
    private let hosting: UIHostingController<OcinSwiftUIGlassBackground>

    init(frame: CGRect) {
        hosting = UIHostingController(rootView: OcinSwiftUIGlassBackground())
        super.init()
        hosting.view.frame = frame
        hosting.view.backgroundColor = .clear
        hosting.view.isUserInteractionEnabled = false
    }

    func view() -> UIView { hosting.view }
}

private struct OcinSwiftUIGlassBackground: View {
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
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
