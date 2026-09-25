import Flutter
import MessageUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  MFMessageComposeViewControllerDelegate {
  private var smsResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "sms_remote/sms",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "compose" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "Compositore non disponibile.", details: nil))
        return
      }
      self.compose(call.arguments, result: result)
    }
  }

  private func compose(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
      let recipient = args["recipient"] as? String,
      recipient.range(of: #"^\+?[0-9]{3,15}$"#, options: .regularExpression) != nil,
      let text = args["text"] as? String,
      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      result(FlutterError(code: "invalid_arguments", message: "Numero o testo non valido.", details: nil))
      return
    }
    guard smsResult == nil else {
      result(FlutterError(code: "busy", message: "Un messaggio è già aperto.", details: nil))
      return
    }
    guard MFMessageComposeViewController.canSendText() else {
      result(FlutterError(code: "unavailable", message: "SMS non disponibili su questo dispositivo.", details: nil))
      return
    }
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    guard let presenter = window?.rootViewController,
      presenter.presentedViewController == nil else {
      result(FlutterError(code: "busy", message: "Impossibile aprire il compositore ora.", details: nil))
      return
    }
    let composer = MFMessageComposeViewController()
    composer.messageComposeDelegate = self
    composer.recipients = [recipient]
    composer.body = text
    composer.disableUserAttachments()
    composer.modalPresentationStyle = .fullScreen
    smsResult = result
    presenter.present(composer, animated: true)
  }

  func messageComposeViewController(
    _ controller: MFMessageComposeViewController,
    didFinishWith result: MessageComposeResult
  ) {
    let callback = smsResult
    controller.dismiss(animated: true) { [weak self] in
      self?.smsResult = nil
      switch result {
      case .sent:
        // Il sistema ha accettato l'invio, non è una ricevuta di consegna.
        callback?("sent")
      case .cancelled:
        callback?("cancelled")
      case .failed:
        callback?(FlutterError(code: "send_failed", message: "Invio non riuscito.", details: nil))
      @unknown default:
        callback?(FlutterError(code: "unexpected_result", message: "Esito non disponibile.", details: nil))
      }
    }
  }
}
