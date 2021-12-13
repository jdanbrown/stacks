import Firebase
import SwiftUI

@main
struct AppMain: App {

  @State var auth: AuthService
  @State var firestore: FirestoreService
  @State var pinsModel: PinsModel

  // SwiftUI init() is the new UIKit AppDelegate application:didFinishLaunchWithOptions:
  //  - https://medium.com/swlh/bye-bye-appdelegate-swiftui-app-life-cycle-58dde4a42d0f
  //  - https://developer.apple.com/forums/thread/653737 -- if you need an AppDelegate
  init() {

    // Before AuthService()
    //  - https://peterfriese.dev/swiftui-new-app-lifecycle-firebase/
    //  - https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/
    FirebaseApp.configure()

    // After FirebaseApp.configure()
    let auth = AuthService()
    let firestore = FirestoreService(auth: auth)
    let pinsModel = PinsModel(firestore: firestore)

    self.auth = auth
    self.firestore = firestore
    self.pinsModel = pinsModel

    // TODO
    // pinsModel.fetchPins()

  }

  // https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  var body: some Scene {
    WindowGroup {
      Group {
        if auth.loading || auth.user == nil {
          LoginView()
        } else {
          RootView()
        }
      }
        .environmentObject(auth)
        .environmentObject(firestore)
        .environmentObject(pinsModel)
        .onOpenURL { AuthService.onOpenURL($0) }
    }
  }

}
