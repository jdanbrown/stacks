import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

  let url: URL

  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.load(URLRequest(url: url))
  }
}

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WebView(url: URL(string: "https://httpbin.org/anything")!)
      WebView(url: URL(string: "https://asdf.com")!)
    }
      .previewLayout(.fixed(width: 350, height: 350))
  }
}
