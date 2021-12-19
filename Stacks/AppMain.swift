import Firebase
import SwiftUI
import XCGLogger

@main
struct AppMain: App {

  var firestore: FirestoreService
  @State var auth: AuthService
  @State var pinsModel: PinsModel

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

    // Before AuthService()
    //  - https://peterfriese.dev/swiftui-new-app-lifecycle-firebase/
    //  - https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/
    FirebaseApp.configure()

    // After FirebaseApp.configure()
    let firestore = FirestoreService()
    let auth = AuthService()
    let pinsModel = PinsModel(auth: auth, firestore: firestore)

    self.auth = auth
    self.firestore = firestore
    self.pinsModel = pinsModel

  }

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    WindowGroup {
      Group {
        RootView()
      }
        .environmentObject(auth)
        .environmentObject(pinsModel)
        .onOpenURL { auth.onOpenURL($0) }
    }
  }

}
