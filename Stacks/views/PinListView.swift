import GameplayKit // For GKMersenneTwisterRandomSource
import SwiftUI

struct PinListView: View {

  @ObservedObject var cloudKitSyncMonitor: CloudKitSyncMonitor

  var logout: () async -> ()
  var user: User
  // var pins: [Pin]
  @ObservedObject var pinsModel: PinsModel

  @State private var dupesOnly: Bool = false // XXX [dupes/races] Debug
  @State private var order: Order = .desc

  // tagFilter is the tag (optional) to filter our pins to
  //  - TODO Generalize this to a "filter"
  //    - Multiple tags + full-text search (maybe that's all?)
  @State private var tagFilter: String? = nil

  // Navigation
  @StateObject var navigation: AutoNavigationLinkModel = AutoNavigationLinkModel()

  @State private var searchFilter: String? = nil
  @FocusState private var searchFilterIsFocused: Bool // TODO The precense of this @FocusState var started crashing previews (why?)

  init(cloudKitSyncMonitor: CloudKitSyncMonitor, logout: @escaping () async -> (), user: User, pinsModel: PinsModel) {
    self.cloudKitSyncMonitor = cloudKitSyncMonitor
    self.logout = logout
    self.user = user
    self.pinsModel = pinsModel
  }

  init(cloudKitSyncMonitor: CloudKitSyncMonitor, logout: @escaping () async -> (), user: User, pinsModel: PinsModel, tagFilter: String?) {
    self.init(cloudKitSyncMonitor: cloudKitSyncMonitor, logout: logout, user: user, pinsModel: pinsModel)
    self.tagFilter = tagFilter
  }

  func navigationPushTag(_ tag: String) {
    navigation.push(withTagFilter(tagFilter: tag))
  }

  func withTagFilter(tagFilter: String?) -> PinListView {
    return PinListView(cloudKitSyncMonitor: cloudKitSyncMonitor, logout: logout, user: user, pinsModel: pinsModel, tagFilter: tagFilter)
  }

  var body: some View {

    let pins = pinsForView()
    // let _ = log.warning("pins[].tags[\(pins.map { $0.tags })]") // XXX Debug

    ZStack {
      AutoNavigationLink(model: navigation)
      VStack(spacing: 5) {
        // HACK_CorePin_list() // XXX Dev
        searchBar()
        // Using List instead of ScrollView so that swipe gestures work
        //  - Gestures in List
        //    - https://developer.apple.com/documentation/SwiftUI/View/swipeActions(edge:allowsFullSwipe:content:)
        //    - https://useyourloaf.com/blog/swiftui-swipe-actions/
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
            pinRow(pin: pin, pins: pins)
          }
        }
          // Use .id to force-rebuild the ScrollView when order changes, to jump to top when cycling order
          .id(order.description)
          .listStyle(.plain)
      }
    }

      // .statusBar(hidden: true) // Want or not?
      .navigationTitle("\(tagFilter ?? "All pins") (\(pins.count))")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: HStack {
          buttonProfilePhoto()
          statusCloudKitSync()
        },
        trailing: HStack {
          buttonSearch()
          // buttonFilterReset()
          buttonOrderCycleDescAscShuffle()
          // buttonOrderToggleDescAsc()
          // buttonOrderShuffle()
          buttonDupesOnlyToggle() // XXX [dupes/races] Debug
        }
      )

  }

  @ViewBuilder
  func searchBar() -> some View {
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
  }

  @ViewBuilder
  func pinRow(pin: Pin, pins: [Pin]) -> some View {
    let isLast = pin.id == pins.last?.id
    PinView(pin: pin, navigationPushTag: navigationPushTag)

      // Replace List separators with custom separators
      //  - List separators don't extend to the left edge, these custom ones do
      .listRowSeparator(.hidden)
      .padding(.init(top: 9, leading: 10, bottom: 9, trailing: 10))
      .overlay(Divider(), alignment: .top)
      .padding(.init(top: 1, leading: 0, bottom: 0, trailing: 0))
      // Curious: .pipe(b ? v : f(v)) makes List scrolling _very_ slow, whereas .overlay(b ? v : EmptyView()) doesn't
      .overlay(isLast ? AnyView(Divider()) : AnyView(EmptyView()), alignment: .bottom)

      // Use .listRowInsets to remove left/right padding on List
      //  - https://programmingwithswift.com/swiftui-list-remove-padding-left-and-right/
      //  - https://stackoverflow.com/questions/68490542/swiftui-remove-the-space-on-list-view-left-and-right
      .listRowInsets(.init())

      // Gestures
      //  - This is tricky, see big comment + links at OnTapAndLongPressGesture
      .modifier(OnTapAndLongPressGesture(
        onTap: {
          log.info("OnTapAndLongPressGesture.onTap")
          // TODO Fix slow nav?!
          //  - The gesture responds fast (as per logging), but the nav seems to respond very slowly
          self.navigation.push(
            ReaderView(pin: pin)
              .ignoresSafeArea(edges: .bottom)
          )
        },
        onLongPress: {
          log.info("OnTapAndLongPressGesture.onLongPress")
          self.navigation.push(
            PinEditView(pin: pin, dismiss: {})
          )
        },
        // TODO Add state+binding to visually indicate the row is being pressed (like Hack.app)
        isLongPressing: Binding(
          get: { true }, // (Unused)
          set: { x in log.info("OnTapAndLongPressGesture.isLongPressing = \(x)") }
        ),
        longPressMinimumDuration: 0.1
      ))

  }

  @ViewBuilder
  func buttonProfilePhoto() -> some View {
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
  }

  @ViewBuilder
  func statusCloudKitSync() -> some View {
    Image(systemName: cloudKitSyncMonitor.syncStateSummary.symbolName)
      .foregroundColor(cloudKitSyncMonitor.syncStateSummary.symbolColor)
      .font(.body)
  }

  // XXX [dupes/races] Debug
  @ViewBuilder
  func buttonDupesOnlyToggle() -> some View {
    Button(action: {
      self.dupesOnly = !self.dupesOnly
    }) {
      Image(systemName: !self.dupesOnly ? "doc.on.doc" : "doc.on.doc.fill")
        .font(.body)
    }
  }

  @ViewBuilder
  func buttonSearch() -> some View {
    // Keyboard management
    //  - https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-focusstate-property-wrapper
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-dismiss-the-keyboard-for-a-textfield
    //    - To force hide the keyboard:
    //      - UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
  }

  @ViewBuilder
  func buttonFilterReset() -> some View {
    Button(action: {
      self.tagFilter = nil
    }) {
      Image(systemName: "xmark")
        .font(.body)
    }
  }

  @ViewBuilder
  func buttonOrderCycleDescAscShuffle() -> some View {
    Button(action: {
      self.order = self.order.cycle()
    }) {
      Image(systemName: self.order.iconName())
        .font(.body)
    }
  }

  @ViewBuilder
  func buttonOrderToggleDescAsc() -> some View {
    Button(action: {
      self.order = self.order.toggleDescAsc()
    }) {
      Image(systemName: self.order.iconName())
        .font(.body)
    }
  }

  @ViewBuilder
  func buttonOrderShuffle() -> some View {
    Button(action: {
      self.order = self.order.shuffle()
    }) {
      Image(systemName: self.order.shuffle().iconName())
        .font(.body)
    }
  }

  func pinsForView() -> [Pin] {
    var pins = self.pinsModel.pins
    // XXX [dupes/races] Debug
    if dupesOnly {
      let urlCounts = Dictionary(grouping: pins, by: { $0.url }).mapValues { $0.count }
      pins = pins.filter { (urlCounts[$0.url] ?? 0) > 1 }
    }
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
        pins = pins.sorted(key: { $0.createdAt ?? Date.zero }, desc: true)
      case .asc:
        pins = pins.sorted(key: { $0.createdAt ?? Date.zero }, desc: false)
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

// TODO Update for Core Data
// struct PinListView_Previews: PreviewProvider {
//   static var previews: some View {
//     let logout: () async -> () = {}
//     let user = User.previewUser0
//     let pins = Pin.previewPins
//     // HACK Split in two to workaround xcode previews not letting you focus views inside a NavigationView
//     // HACK Wrap each in ZStack to avoid FocusState crashing previews
//     //  - https://stackoverflow.com/questions/70430440/why-focusstate-crashing-swiftui-preview
//     ZStack { NavWrap { PinListView(logout: logout, user: user, pins: pins) } }
//     ZStack { PinListView(logout: logout, user: user, pins: pins) }
//   }
// }
