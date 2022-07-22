import SwiftUI

struct ReaderView: View {

  let pin: Pin
  @StateObject var webViewModel: WebViewModel = WebViewModel()

  @State var shareItem: ShareItem?

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

      // Nav bar
      .navigationTitle(webViewModel.url?.host ?? "")
      .navigationBarItems(
        trailing: HStack {
          buttonShare()
        }
      )

      // Share sheet
      //  - TODO(ios16): Change full height -> half height using .presentationDetents
      //    - https://stackoverflow.com/questions/56700752/swiftui-half-modal
      .sheet(item: $shareItem) { shareItem in
        ActivityView(activityItems: [shareItem.item], applicationActivities: nil)
      }

  }

  @ViewBuilder
  func buttonShare() -> some View {
    Button {
      if let url = webViewModel.url {
        shareItem = ShareItem(item: url)
      } else {
        log.warning("Skipping share, no url: webViewModel.url[\(opt: webViewModel.url)]")
      }
    } label: {
      Image(systemName: "square.and.arrow.up")
    }
  }

}

struct ShareItem: Identifiable {
  let item: Any
  let id = UUID() // Unique id per instance so that .sheet() always shows again
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
