import SwiftUI
import XCGLogger

struct ShareView: View {

  let url: URL

  @State var text = ""

  var body: some View {
    VStack {
      Image(systemName: "globe")
      Text("ohai hai")
      Text(text)
      mockPinView()
    }
      .font(.title)
      .onAppear {
        text = url.absoluteString
      }
  }

  @ViewBuilder
  func mockPinView() -> some View {
    let pin = Pin.previewPins.first!
    PinView(pin: pin, navigationPushTag: { tag in () })
  }

}
