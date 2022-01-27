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

  // tagFilter is the tag (optional) to filter our pins to
  //  - TODO Generalize this to a "filter"
  //    - Multiple tags + full-text search (maybe that's all?)
  @State private var tagFilter: String? = nil

  // tagSelection is the control to trigger navigation to withTagFilter(tagFilter: tagSelection)
  //  - HACK State/State/Binding: Conceptually it should just be a single @State, but we implement it in this wacky
  //    State/State/Binding way all so that we can render 1 NavigationLink instead of O(tags) many, which is slow
  //    - Two phases: (1) render an unselected NavigationLink, (2) onAppear, select the rendered NavigationLink
  //      - This makes the enter animation work (on tag) -- with one phase you only get the exit animation (on Back)
  //    - Three states not four: When NavigationLink resets tagSelection = nil, also reset _tagSelectionPhaseTwo = nil
  //      - Else our two-phase rendering logic doesn't work
  @State private var _tagSelection: String? = nil
  @State private var _tagSelectionPhaseTwo: String? = nil
  private var tagSelection: Binding<String?> {
    return Binding(
      get: { _tagSelection },
      set: { new in
        _tagSelection = new
        if new == nil {
          _tagSelectionPhaseTwo = nil
        }
      }
    )
  }

  @State private var searchFilter: String? = nil
  @FocusState private var searchFilterIsFocused: Bool // TODO The precense of this @FocusState var started crashing previews (why?)

  init(logout: @escaping () async -> (), user: User, pins: [Pin]) {
    self.logout = logout
    self.user = user
    self.pins = pins
  }

  init(logout: @escaping () async -> (), user: User, pins: [Pin], tagFilter: String?) {
    self.init(logout: logout, user: user, pins: pins)
    self.tagFilter = tagFilter
  }

  func withTagFilter(tagFilter: String?) -> _PinListView {
    return _PinListView(logout: logout, user: user, pins: pins, tagFilter: tagFilter)
  }

  // TODO TODO Add swipe-right to show edit sheet
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-new-view-using-sheets
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-present-a-full-screen-modal-view-using-fullscreencover
  //  - https://www.hackingwithswift.com/quick-start/swiftui

  var body: some View {
    // Docs
    //  - https://www.hackingwithswift.com/articles/216/complete-guide-to-navigationview-in-swiftui

    let pins = pinsForView()

    ZStack {

      // Tag navigation via tagSelection + tagFilter
      //  - See State/State/Binding above for details
      if let tagSelectionValue = tagSelection.wrappedValue {
        // (1) Render an unselected NavigationLink
        NavigationLink(
          destination: LazyView { withTagFilter(tagFilter: tagSelectionValue) },
          tag: _tagSelectionPhaseTwo ?? "",
          selection: tagSelection
        ) { EmptyView() }
          .hidden()
          .onAppear {
            // (2) Immediately select it
            //  - Without this phase two the enter animation gets skipped
            self._tagSelectionPhaseTwo = tagSelectionValue
          }
      }

      VStack(spacing: 5) {

        // Search bar
        if searchFilter != nil {
          TextField("Filter", text: Binding(
            get: { self.searchFilter ?? "" },
            set: { self.searchFilter = $0 }
          ))
            // TODO Make this focus (i.e. open keyboard) when it appears
            //  - But also allow keyboard to be missed with "Search" button
            //  - Doesn't work: `searchFilterIsFocused = true` in magnifyingglass button (below)
            //  - Doesn't work: `searchFilterIsFocused = true` in TextField.onAppear (below)
            .focused($searchFilterIsFocused)
            .onAppear { self.searchFilterIsFocused = true } // TODO Not working (see above)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .submitLabel(.search)
            .autocapitalization(.none)
            .disableAutocorrection(true) // Or maybe we do want autocorrect? Doubtful
        }

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
                  LazyView {
                    ReaderView(pin: pin)
                      .ignoresSafeArea(edges: .bottom)
                  }
                ) {
                  PinView(pin: pin, tagSelection: tagSelection)
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

          // Search
          //  - Keyboard management
          //    - https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-focusstate-property-wrapper
          //    - https://www.hackingwithswift.com/quick-start/swiftui/how-to-dismiss-the-keyboard-for-a-textfield
          //      - To force hide the keyboard:
          //        - UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
          if searchFilter == nil {
            // Search: Enable
            Button(action: {
              self.searchFilter = ""
              self.searchFilterIsFocused = true // TODO Not working (see above)
            }) {
              Image(systemName: "magnifyingglass")
                .font(.body)
            }
          } else {
            // Search: Close
            Button(action: {
              self.searchFilter = nil
            }) {
              Image(systemName: "xmark.circle")
                .font(.body)
            }
          }

          // // Fitler: Reset
          // Button(action: {
          //   self.tagFilter = nil
          // }) {
          //   Image(systemName: "xmark")
          //     .font(.body)
          // }

          // Order: desc/asc/shuffle
          Button(action: {
            self.order = self.order.cycle()
          }) {
            Image(systemName: self.order.iconName())
              .font(.body)
          }
          // // Order: toggle desc/asc
          // Button(action: {
          //   self.order = self.order.toggleDescAsc()
          // }) {
          //   Image(systemName: self.order.iconName())
          //     .font(.body)
          // }
          // // Order: shuffle
          // Button(action: {
          //   self.order = self.order.shuffle()
          // }) {
          //   Image(systemName: self.order.shuffle().iconName())
          //     .font(.body)
          // }

        }
      )

  }

  func pinsForView() -> [Pin] {
    var pins = self.pins
    // Filter
    if let tagFilter = tagFilter {
      pins = pins.filter { $0.tags.contains(tagFilter) }
    }
    if var searchFilter = searchFilter, searchFilter != "" {
      searchFilter = searchFilter.lowercased()
      pins = pins.filter { pin in
        // TODO Probably slow, but a very simple first implementation
        ((try? toJson(pin)) ?? "").lowercased().contains(searchFilter)
      }
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

    func cycle() -> Order {
      switch self {
        case .desc:    return .asc
        case .asc:     return shuffle()
        case .shuffle: return .desc
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

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    let logout: () async -> () = {}
    let user = User.previewUser0
    let pins = Pin.previewPins
    // HACK Split in two to workaround xcode previews not letting you focus views inside a NavigationView
    // HACK Wrap each in ZStack to avoid FocusState crashing previews
    //  - https://stackoverflow.com/questions/70430440/why-focusstate-crashing-swiftui-preview
    ZStack { PinListView(logout: logout, user: user, pins: pins) }
    ZStack { _PinListView(logout: logout, user: user, pins: pins) }
  }
}
