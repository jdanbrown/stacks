import Firebase
import SwiftUI
import XCGLogger

@main
struct AppMain: App {

  let hasICloud: Bool
  let persistenceController: PersistenceController

  let firestore: FirestoreService
  let auth: AuthService
  let pinsModelFirestore: PinsModelFirestore

  let pinsModelPinboard: PinsModelPinboard

  let pinsModel: PinsModel

  // SwiftUI init() is the new UIKit AppDelegate application:didFinishLaunchWithOptions:
  //  - https://medium.com/swlh/bye-bye-appdelegate-swiftui-app-life-cycle-58dde4a42d0f
  //  - https://developer.apple.com/forums/thread/653737 -- if you need an AppDelegate
  init() {

    // Logging
    //  - https://github.com/DaveWoodCom/XCGLogger
    log.setup(
      level: .debug,
      showThreadName: true,
      showLevel: true,
      showFileNames: true,
      showLineNumbers: true
    )
    log.formatters = [CustomLogFormatter()]
    log.logAppDetails()

    // Check if the user is logged into iCloud, else we'll refuse to load (in RootView, with a helpful error msg)
    //  - https://developer.apple.com/documentation/foundation/nsfilemanager/1408036-ubiquityidentitytoken
    //    - TODO Use `accountStatus() async` instead, as per those docs
    //      - https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus
    //    - TODO Don't require user to restart app after logging in
    //      - This will require the same async handling as the previous bullet
    //  - If we don't _explicitly_ check iCloud, then NSPersistentCloudKitContainer will silently fail to sync and log uncatchable errors
    //    - https://stackoverflow.com/questions/59138880/nspersistentcloudkitcontainer-how-to-check-if-data-is-synced-to-cloudkit
    self.hasICloud = FileManager.default.ubiquityIdentityToken != nil

    // PersistenceController for CloudKit + Core Data
    //  - Touch to init (lazy static let)
    self.persistenceController = PersistenceController.shared

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

    // PinsModel (Core Data)
    let pinsModel = PinsModel(
      persistenceController: persistenceController,
      pinsPublishers: [
        pinsModelFirestore.$pins, // TODO Restore
        pinsModelPinboard.$pins, // TODO Restore
      ]
    )
    // TODO TODO Try loading Pinboard/Firestore _after_ CloudKit, to see if that fixes the duplicate-insert races
    //  - Both call into DispatchQueue.main.async, so they _should_ synchronize
    pinsModel.load()
    pinsModel.addObserverToLoadOnSave() // After CoreData/CloudKit (load) + before Pinboard/Firestore (loadPinsPublishers)
    pinsModel.loadPinsPublishers()

    // Initialize fields
    self.auth = auth
    self.firestore = firestore
    self.pinsModelFirestore = pinsModelFirestore
    self.pinsModelPinboard = pinsModelPinboard
    self.pinsModel = pinsModel

  }

  func initAsync() async {
    log.info()
    await initAsyncPinboard()
  }

  // Fetch pinboard once at startup (http get)
  func initAsyncPinboard() async {
    log.info()
    do {
      // TODO Integrate this with ProgressView() at startup
      //  - Maybe wait until we get Firestore/AuthService out of the picture
      try await pinsModelPinboard.fetch()
    } catch  {
      log.error("Failed to fetch pinboard posts, ignoring: \(error)")
    }
  }

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    AppScene(
      initAsync: initAsync,
      hasICloud: hasICloud,
      persistenceController: persistenceController,
      auth: auth,
      // pinsModelFirestore: pinsModelFirestore,
      // pinsModelPinboard: pinsModelPinboard
      pinsModel: pinsModel
    )
  }

}

struct AppScene: Scene {

  let initAsync: () async -> ()
  let hasICloud: Bool
  let persistenceController: PersistenceController

  @ObservedObject var auth: AuthService
  // @ObservedObject var pinsModelFirestore: PinsModelFirestore
  // @ObservedObject var pinsModelPinboard: PinsModelPinboard
  @ObservedObject var pinsModel: PinsModel

  // Docs
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
  //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-when-your-app-moves-to-the-background-or-foreground-with-scenephase
  //  - https://developer.apple.com/documentation/swiftui/scenephase
  @Environment(\.scenePhase) var scenePhase

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    // let _ = log.warning("pinsModel.corePins[].tagsList[\(pinsModel.corePins.map { $0.tagsList })]") // XXX Debug
    WindowGroup {
      Group {
        RootView(
          hasICloud: hasICloud,
          authState: auth.authState,
          login: auth.login,
          logout: auth.logout,
          // TODO Add the proper PinsModel
          pins: pinsModel.pins
          // pins: pinsModel.corePins,
          // pins: pinsModel.pins
          // pins: pinsModelFirestore.pins
          // pins: pinsModelPinboard.pins
          // pins: pinsModelFirestore.pins.filter { $0.url.starts(with: "http:") } // XXX Debug http:// issues
        )
      }
        .environment(\.managedObjectContext, persistenceController.managedObjectContext)
        .task { await initAsync() }
        .onOpenURL { auth.onOpenURL($0) }
    }
      .onChange(of: scenePhase) { phase in
        log.info("onChange: scenephase[\(phase)]")
        if [.inactive, .background].contains(phase) {
          persistenceController.save()
        }
      }
  }

}
