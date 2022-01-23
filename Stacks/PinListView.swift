import GameplayKit
import SwiftUI

// HACK Workaround xcode previews not letting you focus any views inside a NavigationView
struct PinListView: View {

  var logout: () async -> ()
  var user: User
  var pins: [Pin]

  var body: some View {
    NavigationView {
      _PinListView(logout: logout, user: user, pins: pins)
    }
  }

}

struct _PinListView: View {

  var logout: () async -> ()
  var user: User
  var pins: [Pin]

  @State private var order: Order = .desc

  // TODO Generalize this to a "filter"
  //  - Multiple tags + full-text search (maybe that's all?)
  @State private var tagFilter: String? = nil

  enum Order: CustomStringConvertible {
    case desc
    case asc
    case shuffle(seed: UInt64)

    var description: String {
      switch self {
        case .desc:              return "Order.desc"
        case .asc:               return "Order.asc"
        case .shuffle(let seed): return "Order.shuffle(\(seed))"
      }
    }

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

    let pins = pinsForView()
    VStack(spacing: 5) {
      // Instead of List, use ScrollView + LazyVStack
      //  - https://stackoverflow.com/questions/64309390/swiftui-gap-left-margin-and-change-color-of-list-items-bottom-border
      //  - https://stackoverflow.com/questions/56553672/how-to-remove-the-line-separators-from-a-list-in-swiftui-without-using-foreach
      //  - Bonus: This also results in hiding the NavigationLink "disclosure indicator"
      //    - https://stackoverflow.com/questions/56516333/swiftui-navigationbutton-without-the-disclosure-indicator
      //    - https://www.appcoda.com/hide-disclosure-indicator-swiftui-list/
      ScrollView {
        ScrollViewReader { (scrollViewProxy: ScrollViewProxy) in
          LazyVStack(alignment: .leading) {
            ForEach(pins) { pin in
              Divider()
              NavigationLink(destination:
                ReaderView(pin: pin)
                  .ignoresSafeArea(edges: .bottom)
              ) {
                PinView(pin: pin, tagFilter: $tagFilter)
              }
              .buttonStyle(.plain)
              .padding(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
          }
        }
      }
        // Jump to top on pin reorder: Use .id to force-rebuild the ScrollView when order changes
        .id(order.description)
    }

      // .statusBar(hidden: true) // Want or not?
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("\(tagFilter ?? "All pins") (\(pins.count))")
      .navigationBarItems(
        leading: HStack {
          Button { Task { await logout() }} label: {
            if let photoURL = user.photoURL {
              AsyncImage(url: photoURL) { image in
                image
                  .resizable()
                  .scaledToFit()
                  .clipShape(Circle())
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
          // Fitler: Reset
          Button(action: {
            self.tagFilter = nil
          }) {
            Image(systemName: "xmark.circle")
              .font(.body)
          }
          // Order: toggle desc/asc
          Button(action: {
            self.order = self.order.toggleDescAsc()
          }) {
            Image(systemName: self.order.iconName())
              .font(.body)
          }
          // Order: Shuffle
          Button(action: {
            self.order = self.order.shuffle()
          }) {
            Image(systemName: self.order.shuffle().iconName())
              .font(.body)
          }
        }
      )

  }

  func pinsForView() -> [Pin] {
    var pins = self.pins
    // Filter
    if let tagFilter = tagFilter {
      pins = pins.filter { $0.tags.contains(tagFilter) }
    }
    // Order
    switch order {
      case .desc:
        pins = pins.sorted(key: \.createdAt, desc: true)
      case .asc:
        pins = pins.sorted(key: \.createdAt, desc: false)
      case .shuffle(let seed):
        let generator = GKMersenneTwisterRandomSource(seed: seed)
        pins = generator.arrayByShufflingObjects(in: pins) as! [Pin]
    }
    return pins
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    let logout: () async -> () = {}
    let user = User.previewUser0
    let pins = Pin.previewPins
    // HACK Workaround xcode previews not letting you focus any views inside a NavigationView
    PinListView(logout: logout, user: user, pins: pins)
    _PinListView(logout: logout, user: user, pins: pins)
  }
}
