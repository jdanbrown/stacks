import GameplayKit
import SwiftUI

struct PinListView: View {

  var logout: () async -> ()
  var user: User
  var pins: [Pin]

  @State private var order: Order = .desc

  enum Order {
    case desc
    case asc
    case shuffle(seed: UInt64)

    func iconName() -> String {
      switch self {
        case .desc:    return "arrow.down"
        case .asc:     return "arrow.up"
        case .shuffle: return "shuffle"
      }
    }

    func toggleDescAsc() -> Order {
      switch self {
        case .desc:    return .asc
        case .asc:     return .desc
        case .shuffle: return .desc
      }
    }

    func shuffle() -> Order {
      let seed = UInt64(Date().timeIntervalSince1970)
      return .shuffle(seed: seed)
    }
  }

  // TODO TODO Add swipe-right to show edit sheet
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-full-screen-modal-view-using-fullscreencover
  //  - https://www.hackingwithswift.com/quick-start/swiftui

  var body: some View {
    // Docs
    //  - https://www.hackingwithswift.com/articles/216/complete-guide-to-navigationview-in-swiftui
    NavigationView {
      VStack(spacing: 5) {
        List {
          ForEach(pinsOrdered()) { pin in
            // TODO How to hide the right arrow on the nav link?
            NavigationLink(destination: ReaderView(pin: pin)) {
              PinView(pin: pin)
                // .listRowInsets(EdgeInsets()) // To control padding for each list item
            }
          }
        }
          .listStyle(.plain) // Remove padding + rounded corders
      }
        // .statusBar(hidden: true) // Want or not?
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("\(pins.count) Pins")
        .navigationBarItems(
          leading: HStack {
            Button { Task { await logout() }} label: {
              if let photoURL = user.photoURL {
                AsyncImage(url: photoURL) { image in
                  image.resizable().scaledToFit()
                } placeholder: {
                  ProgressView()
                }
                  .frame(height: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize)
              } else {
                VStack(alignment: .leading) {
                  Text("Logout")
                  Text("\(user.email ?? "[no email?]")")
                }
              }
            }
          },
          trailing: HStack {
            // Order: toggle desc/asc
            Button(action: { self.order = self.order.toggleDescAsc() }) {
              Image(systemName: self.order.iconName())
                .font(.body)
            }
            // Order: Shuffle
            Button(action: { self.order = self.order.shuffle() }) {
              Image(systemName: self.order.shuffle().iconName())
                .font(.body)
            }
          }
        )
    }
  }

  func pinsOrdered() -> [Pin] {
    switch order {
      case .desc:
        return pins.sorted(key: \.createdAt, desc: true)
      case .asc:
        return pins.sorted(key: \.createdAt, desc: false)
      case .shuffle(let seed):
        let generator = GKMersenneTwisterRandomSource(seed: seed)
        return generator.arrayByShufflingObjects(in: pins) as! [Pin]
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    PinListView(
      logout: {},
      user: User.previewUser0,
      pins: Pin.previewPins
    )
  }
}
