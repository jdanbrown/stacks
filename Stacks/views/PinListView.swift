import GameplayKit // For GKMersenneTwisterRandomSource
import SwiftUI

struct PinListView: View {

  let storageProvider: StorageProvider
  @ObservedObject var cloudKitSyncMonitor: CloudKitSyncMonitor

  var logout: () async -> ()
  var user: User
  // var pins: [Pin]
  @ObservedObject var pinsModel: PinsModel
  let pinsModelPinboard: PinsModelPinboard

  @State private var dupesOnly: Bool = false
  @State private var order: Order = .desc

  // tagFilter is the tag (optional) to filter our pins to
  //  - TODO Generalize this to a "filter"
  //    - Multiple tags + full-text search (maybe that's all?)
  @State private var tagFilter: String? = nil

  // Navigation
  @StateObject var navigation: AutoNavigationLinkModel = AutoNavigationLinkModel()

  @State private var searchFilter: String? = nil
  @FocusState private var searchFilterIsFocused: Bool // TODO The precense of this @FocusState var started crashing previews (why?)

  @State private var showAlertBool = false
  @State private var showAlertAlert = Alert(title: Text(""))

  @State private var showingPopoverForCloudKitSyncMonitor = false

  @State private var showDocumentPicker = false

  init(
    storageProvider: StorageProvider,
    cloudKitSyncMonitor: CloudKitSyncMonitor,
    logout: @escaping () async -> (),
    user: User,
    pinsModel: PinsModel,
    pinsModelPinboard: PinsModelPinboard
  ) {
    self.storageProvider = storageProvider
    self.cloudKitSyncMonitor = cloudKitSyncMonitor
    self.logout = logout
    self.user = user
    self.pinsModel = pinsModel
    self.pinsModelPinboard = pinsModelPinboard
  }

  init(
    storageProvider: StorageProvider,
    cloudKitSyncMonitor: CloudKitSyncMonitor,
    logout: @escaping () async -> (),
    user: User,
    pinsModel: PinsModel,
    pinsModelPinboard: PinsModelPinboard,
    tagFilter: String?
  ) {
    self.init(
      storageProvider: storageProvider,
      cloudKitSyncMonitor: cloudKitSyncMonitor,
      logout: logout,
      user: user,
      pinsModel: pinsModel,
      pinsModelPinboard: pinsModelPinboard
    )
    self.tagFilter = tagFilter
  }

  func withTagFilter(tagFilter: String?) -> PinListView {
    return PinListView(
      storageProvider: storageProvider,
      cloudKitSyncMonitor: cloudKitSyncMonitor,
      logout: logout,
      user: user,
      pinsModel: pinsModel,
      pinsModelPinboard: pinsModelPinboard,
      tagFilter: tagFilter
    )
  }

  func navigationPushTag(_ tag: String) {
    navigation.push(withTagFilter(tagFilter: tag))
  }

  var body: some View {

    let pins = pinsForView()

    ZStack {
      AutoNavigationLink(model: navigation)
      VStack(spacing: 5) {
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
          // buttonProfilePhoto()
          menuCloudKitSync()
        },
        trailing: HStack {
          buttonSearch()
          menuOrder()
          menuEllpisis()
        }
      )

      // Generic alerts
      .alert(isPresented: $showAlertBool) {
        showAlertAlert
      }

      // Document picker
      .sheet(isPresented: $showDocumentPicker) {
        if let backupsDir = try? Backup.backupsDir() {
          DocumentPicker(
            forOpeningContentTypes: [.folder],
            allowsMultipleSelection: false,
            directoryURL: backupsDir
          ) { urls in
            let backupDir = urls[0]
            if backupDir.deletingLastPathComponent() == backupsDir {
              do {
                try storageProvider.upsertFromBackup(backupDir: backupDir)
                showAlert(title: "Loaded from backup", message: "\(backupDir.lastPathComponent)")
              } catch {
                showAlert(title: "Failed to load from backup", message: "\(error)")
              }
            } else {
              let _ = {
                showDocumentPicker = false
                showAlert(title: "Invalid backup dir", message: "Must be a child of backupsDir[\(backupsDir)]")
              }()
            }
          }
        } else {
          let _ = {
            showDocumentPicker = false
            showAlert(title: "Failed to open iCloud Drive directory", message: "")
          }()
        }
      }

  }

  func showAlert(title: String, message: String) {
    showAlertBool = true
    showAlertAlert = Alert(
      title: Text(title),
      message: Text(message)
    )
  }

  func showAlertPrimarySecondary(title: String, message: String, primaryButton: Alert.Button, secondaryButton: Alert.Button) {
    showAlertBool = true
    showAlertAlert = Alert(
      title: Text(title),
      message: Text(message),
      primaryButton: primaryButton,
      secondaryButton: secondaryButton
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
            PinEditView(
              pin: pin,
              pinsModel: pinsModel,
              onSave: { storageProvider.fetchPinsFromCoreData() } // Fetch 5/3 on PinEditView save
            )
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
  func menuCloudKitSync() -> some View {
    Menu {
      Button(action: {
        showingPopoverForCloudKitSyncMonitor = true
      }) {
        Label("iCloud Status", systemImage: "info.circle")
      }
      Button(action: {
        Task {
          await self.pinsModelPinboard.fetchAsync()
        }
      }) {
        Label("Fetch Pinboard", systemImage: "tray.and.arrow.down")
      }
    } label: {
      Image(systemName: cloudKitSyncMonitor.syncStateSummary.symbolName)
        .foregroundColor(cloudKitSyncMonitor.syncStateSummary.symbolColor)
        .font(.body)
    }
      .popover(isPresented: $showingPopoverForCloudKitSyncMonitor) {
        VStack(alignment: .leading) {
          Text("CloudKit Sync Status")
            .font(.title)
            .padding()
          let lines = cloudKitSyncMonitor.descriptionDictionary.map { "\($0.key): \($0.value)" }
          ForEach(lines, id: \.self) { line in
            Text(line)
              .padding()
          }
        }
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
        Image(systemName: "line.3.horizontal.decrease.circle")
          .font(.body)
      }
    } else {
      // Search: Close
      Button(action: {
        self.searchFilter = nil
      }) {
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .font(.body)
      }
    }
  }

  @ViewBuilder
  func menuOrder() -> some View {
    Menu {
      Button(action: { self.order = .desc }) {
        Label("Newest First", systemImage: Order.desc.iconName())
          .font(.body)
      }
      Button(action: { self.order = .asc }) {
        Label("Oldest First", systemImage: Order.asc.iconName())
          .font(.body)
      }
      Button(action: { self.order = Order.shuffle() }) {
        Label("Shuffle", systemImage: Order.shuffle().iconName())
          .font(.body)
      }
    } label: {
      Image(systemName: self.order.iconName())
        .font(.body)
    }
  }

  @ViewBuilder
  func menuEllpisis() -> some View {
    Menu {
      buttonsDupesOnly()
      Divider()
      buttonsBackupSaveLoad()
      Divider()
      buttonsDeleteAllState()
    } label: {
      Image(systemName: "ellipsis")
        .font(.body)
    }
  }

  @ViewBuilder
  func buttonsDupesOnly() -> some View {
    Group {
      Button(action: {
        self.dupesOnly = !self.dupesOnly
      }) {
        Label("Dupes Only", systemImage: !self.dupesOnly ? "doc.on.doc" : "doc.on.doc.fill")
          .font(.body)
      }
    }
  }

  @ViewBuilder
  func buttonsBackupSaveLoad() -> some View {
    Group {
      Button(action: {
        do {
          let (alreadyExists, backupDir) = try storageProvider.saveToBackup()
          showAlert(
            title: alreadyExists ? "Backup already exists" : "Saved to backup",
            message: "\(backupDir.lastPathComponent)"
          )
        } catch {
          showAlert(title: "Failed to save backup", message: "\(error)")
        }
      }) {
        Label("Save to Backup", systemImage: "folder")
          .font(.body)
      }
      Button(action: {
        showDocumentPicker = true
      }) {
        Label("Load from Backup", systemImage: "folder.badge.plus")
          .font(.body)
      }
    }
  }

  @ViewBuilder
  func buttonsDeleteAllState() -> some View {
    Group {
      Button(action: {
        showAlertPrimarySecondary(
          title: "Delete all state?",
          message: "A backup will be automatically saved first",
          primaryButton: .destructive(Text("Delete")) {
            // HACK Task so that we can set state for the subsequent Alert from within the current Alert
            //  - Else the subsequent showAlert() silently does nothing
            Task {
              do {
                let (_, autosaveBackupDir) = try storageProvider.deleteAllState()
                showAlert(title: "Deleted all state", message: "Previous state saved as backup: \(autosaveBackupDir.lastPathComponent)")
              } catch {
                showAlert(title: "Failed to delete state", message: "\(error)")
              }
            }
          },
          secondaryButton: .cancel()
        )
      }) {
        Label("Delete all state...", systemImage: "trash")
          .font(.body)
      }
    }
  }

  // TODO Can we change all of this logic into a @FetchRequest?
  //  - Need a dynamic predicate (https://paper.dropbox.com/doc/Book-Practical-Core-Data-2021--Bkr684S2XUvs4CwBekORjii0Ag-2oNrbw8DeArsQeJx5B9fP)
  //  - Will have trouble with some parts (e.g. dupesOnly)
  func pinsForView() -> [Pin] {
    var pins = self.pinsModel.pins
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
        pins = pins.sorted(key: { $0.createdAt }, desc: true)
      case .asc:
        pins = pins.sorted(key: { $0.createdAt }, desc: false)
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
        case .asc:     return Order.shuffle()
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

    static func shuffle() -> Order {
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
