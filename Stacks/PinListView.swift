import GameplayKit
import SwiftUI

struct PinListView: View {

  var user: User
  var pins: [Pin]

  @State private var order: Order = .desc

  enum Order {
    case desc
    case shuffle(seed: UInt64)
  }

  var body: some View {
    VStack {
      HStack {
        Spacer()
        Text("\(pins.count) Pins")
        Spacer()
        HStack {
          Button("Desc", action: {
            self.order = .desc
          })
          Button("Shuf", action: {
            let seed = UInt64(Date().timeIntervalSince1970)
            self.order = .shuffle(seed: seed)
          })
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
      case .shuffle(let seed):
        let generator = GKMersenneTwisterRandomSource(seed: seed)
        return generator.arrayByShufflingObjects(in: pins) as! [Pin]
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    PinListView(
      user: User.example0,
      pins: loadPreviewJson("personal/preview-pins.json")
    )
  }

}
