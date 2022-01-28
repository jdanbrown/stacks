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

  // Programmatic navigation (for any View)
  //  - Conceptually this is just one @State, but we have to do State/State/Binding to render the NavigationLink in two
  //    phases, which we need so that the enter animation doesn't get skipped
  //  - Phase 1: render an unselected NavigationLink -> phase 2: onAppear, select the rendered NavigationLink
  //  - The Binding is to give us 3 states instead of 4: when NavigationLink resets _tagSelectionPhaseTwo = false, also
  //    reset _navigationPush = nil, else our two-phase rendering logic breaks down
  @State private var _navigationPush: AnyView? = nil
  @State private var _navigationPushPhaseTwo: Bool = false
  private var navigationPushPhaseTwo: Binding<Bool> {
    return Binding(
      get: { _navigationPushPhaseTwo },
      set: { x in
        _navigationPushPhaseTwo = x
        if x == false {
          _navigationPush = nil
        }
      }
    )
  }
  func navigationPush<X: View>(_ view: X) {
    _navigationPush = AnyView(view)
  }
  func navigationPushTag(_ tag: String) {
    navigationPush(withTagFilter(tagFilter: tag))
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

      // Programmatic navigation (for any View)
      //  - See details above
      if let _navigationPush = _navigationPush {
        // Phase 1: Render an unselected NavigationLink
        NavigationLink(
          destination: _navigationPush,
          isActive: navigationPushPhaseTwo
        ) { EmptyView() }
          .hidden()
          .onAppear {
            // Phase 2: Immediately select it
            self._navigationPushPhaseTwo = true
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

        // Using List instead of ScrollView so that swipe gestures work
        //  - Gestures in List
        //    - https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-custom-swipe-action-buttons-to-a-list-row
        //  - How to ScrollView(LazyVStack(...)), in case we want to try that again
        //    - https://developer.apple.com/documentation/swiftui/lazyvstack
        //    - https://www.hackingwithswift.com/quick-start/swiftui/how-to-lazy-load-views-using-lazyvstack-and-lazyhstack
        //    - https://stackoverflow.com/questions/64309390/swiftui-gap-left-margin-and-change-color-of-list-items-bottom-border
        //    - https://stackoverflow.com/questions/56553672/how-to-remove-the-line-separators-from-a-list-in-swiftui-without-using-foreach
        //  - Maybe how to make swipe gestures work in ScrollView
        //    - https://developer.apple.com/documentation/swiftui/gestures
        //    - https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures
        //    - https://www.hackingwithswift.com/books/ios-swiftui/how-to-use-gestures-in-swiftui
        //    - https://stackoverflow.com/questions/64573755/swiftui-scrollview-with-tap-and-drag-gesture
        List {
          ForEach(pins) { pin in
            PinView(pin: pin, navigationPushTag: navigationPushTag)
              .padding(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
              // Use .listRowInsets to remove left/right padding on List
              //  - https://programmingwithswift.com/swiftui-list-remove-padding-left-and-right/
              //  - https://stackoverflow.com/questions/68490542/swiftui-remove-the-space-on-list-view-left-and-right
              .listRowInsets(.init())
              .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                  // TODO Show edit view/sheet
                } label: {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.purple)
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                  // TODO pin.isRead.toggle()
                } label: {
                  if pin.isRead {
                    Label("Mark unread", systemImage: "doc")
                  } else {
                    Label("Mark read", systemImage: "doc.fill")
                  }
                }
                  .tint(.blue)
              }
              .onTapGesture {
                log.info("tap")
                self.navigationPush(
                  ReaderView(pin: pin)
                    .ignoresSafeArea(edges: .bottom)
                )
              }
              .onLongPressGesture {
                log.info("longPress")
              }
          }
        }.listStyle(.plain)
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
