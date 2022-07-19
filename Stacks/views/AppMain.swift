import Combine
import Firebase
import SwiftUI
import XCGLogger

@main
class AppMain: App {

  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool
  let storageProvider: StorageProvider

  let pinsPublishers: [Published<[Pin]>.Publisher]

  let firestore: FirestoreService
  let auth: AuthService
  let pinsModelFirestore: PinsModelFirestore

  let pinsModelPinboard: PinsModelPinboard

  let pinsModel: PinsModel

  var cancellables = Set<AnyCancellable>()

  // SwiftUI init() is the new UIKit AppDelegate application:didFinishLaunchWithOptions:
  //  - https://medium.com/swlh/bye-bye-appdelegate-swiftui-app-life-cycle-58dde4a42d0f
  //  - https://developer.apple.com/forums/thread/653737 -- if you need an AppDelegate
  required init() {

    initLogging()

    self.cloudKitSyncMonitor = CloudKitSyncMonitor()
    self.cloudKitSyncMonitor.start()

    // Check if the user is logged into iCloud, else we'll refuse to load (in RootView, with a helpful error msg)
    //  - https://developer.apple.com/documentation/foundation/nsfilemanager/1408036-ubiquityidentitytoken
    //    - TODO Use `accountStatus() async` instead, as per those docs
    //      - https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus
    //    - TODO Don't require user to restart app after logging in
    //      - This will require the same async handling as the previous bullet
    //  - If we don't _explicitly_ check iCloud, then NSPersistentCloudKitContainer will silently fail to sync and log uncatchable errors
    //    - https://stackoverflow.com/questions/59138880/nspersistentcloudkitcontainer-how-to-check-if-data-is-synced-to-cloudkit
    self.hasICloud = FileManager.default.ubiquityIdentityToken != nil

    // Firestore
    //  - Must call configure() before AuthService()
    //    - https://peterfriese.dev/swiftui-new-app-lifecycle-firebase/
    //    - https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/
    FirebaseApp.configure()
    let firestore = FirestoreService()
    let auth = AuthService()
    let pinsModelFirestore = PinsModelFirestore(auth: auth, firestore: firestore)

    // Pinboard
    let pinsModelPinboard = PinsModelPinboard(apiToken: PINBOARD_API_TOKEN)

    // Pins publishersA for Pinboard + Firestore
    self.pinsPublishers = [
      pinsModelFirestore.$pins,
      pinsModelPinboard.$pins,
    ]

    // StorageProvider for CloudKit + Core Data
    //  - Touch to init (lazy static let)
    self.storageProvider = StorageProvider(cloudKitSyncMonitor: cloudKitSyncMonitor)
    self.storageProvider.start()

    // PinsModel (Core Data)
    let pinsModel = PinsModel(storageProvider: storageProvider)
    storageProvider.pinsModel = pinsModel // HACK Cyclic dependency
    storageProvider.fetchPinsFromCoreData() // Fetch 1/3 from Core Data (before CloudKit sync)

    // Set fields
    self.auth = auth
    self.firestore = firestore
    self.pinsModelFirestore = pinsModelFirestore
    self.pinsModelPinboard = pinsModelPinboard
    self.pinsModel = pinsModel

  }

  // XXX after we remove Pinboard/Firestore
  func upsertPinsFromPinsPublishers() {
    log.info("pinsPublishers[\(pinsPublishers)]")
    pinsPublishers.forEach { $0
      .receive(on: RunLoop.main)
      .sink { pins in self.storageProvider.upsertPins(pins) }
      .store(in: &cancellables)
    }
  }

  func initAsync() async {
    log.info()

    // Can't do this in init() because can't pass self before init is complete
    self.storageProvider.onCloudKitImportComplete!
      .sink { _ in self.upsertPinsFromPinsPublishers() }
      .store(in: &cancellables)

    // Fetch pinboard pins once at startup (http get)
    await pinsModelPinboard.fetchAsync()
  }

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    AppScene(
      storageProvider: storageProvider,
      cloudKitSyncMonitor: cloudKitSyncMonitor,
      hasICloud: hasICloud,
      auth: auth,
      pinsModel: pinsModel,
      pinsModelPinboard: pinsModelPinboard,
      initAsync: initAsync
    )
  }

}

struct AppScene: Scene {

  let storageProvider: StorageProvider
  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool

  @ObservedObject var auth: AuthService
  @ObservedObject var pinsModel: PinsModel
  let pinsModelPinboard: PinsModelPinboard

  let initAsync: () async -> ()

  // Docs
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-when-your-app-moves-to-the-background-or-foreground-with-scenephase
  //  - https://developer.apple.com/documentation/swiftui/scenephase
  @Environment(\.scenePhase) var scenePhase

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    WindowGroup {
      Group {
        RootView(
          storageProvider: storageProvider,
          cloudKitSyncMonitor: cloudKitSyncMonitor,
          hasICloud: hasICloud,
          authState: auth.authState,
          login: auth.login,
          logout: auth.logout,
          pinsModel: pinsModel,
          pinsModelPinboard: pinsModelPinboard
        )
      }
        .environment(\.managedObjectContext, storageProvider.viewContext)
        .task { await initAsync() }
        .onOpenURL { auth.onOpenURL($0) }
    }
      .onChange(of: scenePhase) { phase in
        log.info("onChange: scenephase[\(phase)]")
        if [.inactive, .background].contains(phase) {
          storageProvider.saveViewContext()
        }
      }
  }

}
