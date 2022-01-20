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
      // TODO Do we want to show the title or url?
      .navigationTitle(webViewModel.title ?? "")
      // .navigationTitle(webViewModel.url?.absoluteString ?? "")
  }

}

struct ReaderView_Previews: PreviewProvider {
  static var previews: some View {
    let pins = Pin.previewPins
    ReaderView(pin: pins[0])
      .previewLayout(.sizeThatFits)
  }
}
