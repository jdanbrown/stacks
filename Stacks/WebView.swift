import SwiftUI
import WebKit

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

class WebViewModel: ObservableObject {

  // let url: URL

  @Published var wkWebView: WKWebView = WKWebView()
  @Published var coordinator: WebView.Coordinator? = nil
  @Published var debug: String = "init"

  private var estimatedProgressObservation: NSKeyValueObservation?

  // init(url: URL) {
  //   self.url = url

  init() {

    // Observe navigation events
    coordinator = WebView.Coordinator(self)
    wkWebView.navigationDelegate = coordinator!

    // Observe changes to .estimatedProgress (KVO)
    //  - https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift
    //  - https://www.hackingwithswift.com/example-code/wkwebview/how-to-monitor-wkwebview-page-load-progress-using-key-value-observing
    estimatedProgressObservation = wkWebView.observe(\.estimatedProgress) { object, change in
      self.observeEstimatedProgress(wkWebView: self.wkWebView, estimatedProgress: self.wkWebView.estimatedProgress)
    }

  }

  func load(_ url: URL) {
    wkWebView.load(URLRequest(url: url))
  }

  func observeEstimatedProgress(wkWebView: WKWebView, estimatedProgress: Double) {
    log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], estimatedProgress[\(estimatedProgress)]")
    debug = "estimatedProgress[\(estimatedProgress)]"
    // TODO
  }

}

final class WebView: UIViewRepresentable {

  // TODO TODO How to avoid loop on `model.debug =` updates? -- everything else is working great!
  // @Binding var model: Model // TODO This version doesn't update (maybe because of nested fields?)
  // @ObservedObject var model: Model  // TODO This version loops on update

  // let url: URL

  // init(
  //   // model: Binding<Model>,
  //   model: Model,
  //   url: URL
  // ) {
  //   // self._model = model
  //   self.model = model
  //   self.url = url
  // }

  // let wkWebView: WKWebView
  // let coordinator: Coordinator

  // init(wkWebView: WKWebView, coordinator: Coordinator) {
  //   self.wkWebView = wkWebView
  //   self.coordinator = coordinator
  // }

  let model: WebViewModel

  init(model: WebViewModel) {
    self.model = model
  }

  func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
    log.debug() // Don't log context (very big)
    // return wkWebView
    // return WKWebView() // TODO This version loops on update
    // return model.wkWebView // TODO Does this avoid loop?
    return model.wkWebView
  }

  static func dismantleUIView(_ wkWebView: WKWebView, coordinator: Coordinator) {
    log.debug("wkWebView[\(wkWebView)], coordinator[\(coordinator)]")
    wkWebView.stopLoading() // Else WKWebView will keep loading page content for no one to see
  }

  func makeCoordinator() -> Coordinator {
    log.debug()
    // return Coordinator(model)
    return model.coordinator!
  }

  func updateUIView(_ wkWebView: WKWebView, context: UIViewRepresentableContext<WebView>) {
    // wkWebView.navigationDelegate = context.coordinator
    // let urlRequest = URLRequest(url: url)
    // wkWebView.load(urlRequest)
  }

  // https://developer.apple.com/documentation/webkit/wknavigationdelegate
  class Coordinator: NSObject, WKNavigationDelegate {
    let model: WebViewModel
    init(_ model: WebViewModel) { self.model = model }

    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
      model.debug = "didStartProvisionalNavigation"
      // TODO
    }

    func webView(_ wkWebView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
      model.debug = "didReceiveServerRedirectForProvisionalNavigation"
    }

    func webView(_ wkWebView: WKWebView, didCommit navigation: WKNavigation!) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
      model.debug = "didCommit"
    }

    func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)]")
      model.debug = "didFinish"
      // TODO
    }

    func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)], error[\(error)]")
      model.debug = "didFail"
      // TODO
    }

    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      log.debug("url[\(wkWebView.url?.absoluteString ?? "nil")], navigation[\(opt: navigation)], error[\(error)]")
      model.debug = "didFailProvisionalNavigation"
      // TODO
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

  }

}

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    // Group {
      ForEach([
        "https://httpbin.org/anything",
        "https://asdf.com",
      ], id: \.self) { url in
        // WebView(model: .constant(WebView.Model()), url: URL(string: url)!)
        // WebView(model: WebView.Model(), url: URL(string: url)!)
        let model = WebViewModel()
        WebView(model: model)
          .onAppear { model.load(URL(string: url)!) }
      }
    // }
      .previewLayout(.fixed(width: 350, height: 350))
  }
}
