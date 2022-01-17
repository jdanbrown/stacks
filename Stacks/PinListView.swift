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

  var body: some View {
    VStack(spacing: 5) {
      HStack {
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
          .padding(.leading)
        Spacer()
        Text("\(pins.count) Pins")
        Spacer()
        HStack {
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
          .padding(.trailing)
      }
      List {
        ForEach(pinsOrdered()) { pin in
          PinView(pin: pin)
            // .listRowInsets(EdgeInsets()) // To control padding for each list item
        }
      }
        .listStyle(.plain) // Remove padding + rounded corders
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
