import SwiftUI

struct ReaderView: View {

  let pin: Pin
  @StateObject var webViewModel: WebViewModel = WebViewModel()

  var body: some View {
    ZStack(alignment: .top) {
      WebView(model: webViewModel)
        .onAppear { webViewModel.load(URL(string: pin.url)!) }
      // ZStack the transient ProgressView so it doesn't offset the WebView when it disappears
      if webViewModel.estimatedProgress < 1 {
        ProgressView(value: webViewModel.estimatedProgress)
          .frame(height: 1) // Match height of Divider
      }
    }
      .navigationTitle(webViewModel.url?.host ?? "")
  }

}

struct ReaderView_Previews: PreviewProvider {
  static var previews: some View {
    let pins = Pin.previewPins
    let pin = pins[0]
    Group {
      ReaderView(pin: pin)
      // Add another with nav view to preview .navigationTitle
      NavigationView {
        ReaderView(pin: pin)
          .navigationBarTitleDisplayMode(.inline)
      }
    }
      .previewLayout(.sizeThatFits)
  }
}
