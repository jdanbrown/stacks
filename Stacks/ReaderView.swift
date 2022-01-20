import SwiftUI

struct ReaderView: View {

  let pin: Pin
  // @ObservedObject var webViewModel: WebView.Model = WebView.Model() // TODO
  // @State var webViewModel: WebView.Model = WebView.Model() // TODO This version doesn't update (maybe because of nested fields?)
  // @StateObject var webViewModel: WebView.Model = WebView.Model() // TODO This version loops on update
  @StateObject var webViewModel: WebViewModel = WebViewModel()

  var body: some View {
    VStack {
      Text("\n\n" + "\(webViewModel.debug)") // XXX
      WebView(
        // model: $webViewModel,
        model: webViewModel
        // url: URL(string: pin.url)!
      )
        .onAppear { webViewModel.load(URL(string: pin.url)!) }
    }
      .navigationTitle(pin.url)
  }

}

struct ReaderView_Previews: PreviewProvider {
  static var previews: some View {
    let pins = Pin.previewPins
    ReaderView(pin: pins[0])
      .previewLayout(.sizeThatFits)
  }
}
