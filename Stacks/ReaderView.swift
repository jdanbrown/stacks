import SwiftUI

struct ReaderView: View {

  let pin: Pin

  var body: some View {
    VStack {
      WebView(url: URL(string: pin.url)!)
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
