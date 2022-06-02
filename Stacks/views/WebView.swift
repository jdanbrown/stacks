import SwiftUI
import WebKit

// Getting this Model/View relationship right was tricky, I kept causing swiftui update loops. I finally got it to work
// by following this example:
//  - https://github.com/kylehickinson/SwiftUI-WebView
//  - https://github.com/kylehickinson/SwiftUI-WebView/blob/main/Sources/WebView/WebView.swift
//  - Key idea: Let views be disposable, never recreate model state
//
// More stuff we can do with WKWebView
//  - https://www.hackingwithswift.com/articles/112/the-ultimate-guide-to-wkwebview
//    - Add our own js alerts/prompts ("it won't even show alerts or confirmation requests triggered by JavaScript")
//    - Monitoring .title as the user navigates through pages
//    - Intercept page navigation (e.g. download pdf)
//  - https://medium.com/@mdyamin/swiftui-mastering-webview-5790e686833e
//    - Run js in the page
//    - Send data back from js you run in the page
//  - https://developer.apple.com/documentation/uikit/uicontrol/adding_context_menus_in_your_app
//    - Add custom context menus (e.g. for links)
//  - https://benoitpasquier.com/create-webview-in-swiftui
//    - Complete example with nav controls
//    - How to use Combine
//  - https://swiftuirecipes.com/blog/webview-in-swiftui
//    - Complete example with nav controls

// Docs
//  - https://developer.apple.com/documentation/webkit/wkwebview
class WebViewModel: ObservableObject {

  @Published var wkWebView: WKWebView = WKWebView()
  @Published var delegate: WebViewDelegate? = nil
  // @Published var debug: String = "init"

  // private var estimatedProgressObservation: NSKeyValueObservation?

  private var observers: [NSKeyValueObservation] = []

  init() {

    // Observe navigation events
    delegate = WebViewDelegate(self)
    wkWebView.navigationDelegate = delegate
    wkWebView.uiDelegate = delegate

    // Observe changes to fields like .estimatedProgress (KVO)
    //  - Following example: https://github.com/kylehickinson/SwiftUI-WebView/blob/main/Sources/WebView/WebView.swift
    //  - https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift
    //  - https://www.hackingwithswift.com/example-code/wkwebview/how-to-monitor-wkwebview-page-load-progress-using-key-value-observing
    func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
      return wkWebView.observe(keyPath, options: [.prior]) { _, change in
        if change.isPrior {
          self.objectWillChange.send()
        }
      }
    }
    observers = [
      subscriber(for: \.title),
      subscriber(for: \.url),
      subscriber(for: \.isLoading),
      subscriber(for: \.estimatedProgress),
      subscriber(for: \.hasOnlySecureContent),
      subscriber(for: \.serverTrust),
      subscriber(for: \.canGoBack),
      subscriber(for: \.canGoForward)
    ]

  }

  var title:                String?   { get { return wkWebView.title } }
  var url:                  URL?      { get { return wkWebView.url } }
  var isLoading:            Bool      { get { return wkWebView.isLoading } }
  var estimatedProgress:    Double    { get { return wkWebView.estimatedProgress } }
  var hasOnlySecureContent: Bool      { get { return wkWebView.hasOnlySecureContent } }
  var serverTrust:          SecTrust? { get { return wkWebView.serverTrust } }
  var canGoBack:            Bool      { get { return wkWebView.canGoBack } }
  var canGoForward:         Bool      { get { return wkWebView.canGoForward } }

  func load(_ url: URL) {
    wkWebView.load(URLRequest(url: url))
  }

}

// Docs
//  - https://developer.apple.com/documentation/swiftui/uiviewrepresentable
final class WebView: UIViewRepresentable {

  let model: WebViewModel

  init(model: WebViewModel) {
    self.model = model
  }

  func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
    log.debug() // Don't log context (it's very big)
    return model.wkWebView
  }

  func makeCoordinator() -> WebViewDelegate {
    log.debug()
    return model.delegate!
  }

  func updateUIView(_ wkWebView: WKWebView, context: UIViewRepresentableContext<WebView>) {
  }

  static func dismantleUIView(_ wkWebView: WKWebView, coordinator: WebViewDelegate) {
    log.debug("wkWebView[\(wkWebView)], coordinator[\(coordinator)]")
    wkWebView.stopLoading() // Else WKWebView will keep loading page content for no one to see
  }

}

// Docs
//  - https://developer.apple.com/documentation/webkit/wknavigationdelegate
//  - https://developer.apple.com/documentation/webkit/wkuidelegate
class WebViewDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
  let model: WebViewModel
  init(_ model: WebViewModel) { self.model = model }

  // WKNavigationDelegate

  func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
  }

  func webView(_ wkWebView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
  }

  func webView(_ wkWebView: WKWebView, didCommit navigation: WKNavigation!) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
  }

  func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
  }

  func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)], error[\(error)]")
    // TODO Handle failed to load (e.g. http:)
  }

  func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)], error[\(error)]")
    // TODO Handle failed to load (e.g. http:)
  }

  func webViewWebContentProcessDidTerminate(_ wkWebView: WKWebView) {
    log.debug()
  }

  func webView(_ wkWebView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
    log.debug("download[\(download)]")
  }

  func webView(_ wkWebView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
    log.debug("download[\(download)]")
  }

  // WKUIDelegate

  func webView(
    _ wkWebView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    log.debug("navigationAction[\(navigationAction)], windowFeatures[\(windowFeatures)]")
    // Open links with target="_blank" (open in new window) in the current window
    //  - By default WKWebView noops on these, because it doesn't handle multiple windows for us
    //  - https://stackoverflow.com/questions/25713069/why-is-wkwebview-not-opening-links-with-target-blank
    //  - https://stackoverflow.com/questions/49902667/links-opening-in-new-window-or-tab-is-not-loaded-in-native-ios
    //  - https://stackoverflow.com/questions/48073805/wkwebview-target-blank-link-open-new-tab-in-safari-ios11-swift-4
    wkWebView.load(navigationAction.request)
    return nil
  }

  func webViewDidClose(_ wkWebView: WKWebView) {
    log.debug()
  }

  func webView(
    _ wkWebView: WKWebView,
    runJavaScriptAlertPanelWithMessage: String,
    initiatedByFrame: WKFrameInfo, completionHandler: () -> Void
  ) {
    log.debug()
    // TODO Handle js alert dialogs
  }

  func webView(
    _ wkWebView: WKWebView,
    runJavaScriptConfirmPanelWithMessage: String,
    initiatedByFrame: WKFrameInfo,
    completionHandler: (Bool) -> Void
  ) {
    log.debug()
    // TODO Handle js ok/cancel dialogs
  }

  func webView(
    _ wkWebView: WKWebView,
    runJavaScriptTextInputPanelWithPrompt: String,
    defaultText: String?,
    initiatedByFrame: WKFrameInfo,
    completionHandler: (String?) -> Void
  ) {
    log.debug()
    // TODO Handle js text inputs dialogs
  }

}

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    ForEach([
      "https://httpbin.org/anything",
      "https://asdf.com",
    ], id: \.self) { url in
      let model = WebViewModel()
      WebView(model: model)
        .onAppear { model.load(URL(string: url)!) }
    }
      .previewLayout(.fixed(width: 350, height: 350))
  }
}
