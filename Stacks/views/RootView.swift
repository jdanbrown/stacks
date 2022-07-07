import SwiftUI

struct RootView: View {

  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool
  var authState: AuthState
  var login: () async -> ()
  var logout: () async -> ()
  var pins: [Pin]

  var body: some View {
    // let _ = log.warning("pins[].tags[\(pins.map { $0.tags })]") // XXX Debug
    VStack {
      if !hasICloud {
        Text("Please log into iCloud (in the Settings app), and then restart this app")
      } else {
        switch authState {
          case .Loading:
            ProgressView()
          case .LoggedOut:
            LoginView(login: login)
          case .LoggedIn(let user):
            NavWrap {
              PinListView(
                cloudKitSyncMonitor: cloudKitSyncMonitor,
                logout: logout,
                user: user,
                pins: pins
              )
            }
        }
      }
    }
  }

}

// TODO Update for Core Data
// struct RootView_Previews: PreviewProvider {
//   static var previews: some View {
//     let user = User.previewUser0
//     let pins = Pin.previewPins
//     Group {
//       RootView(hasICloud: false, authState: .Loading, login: {}, logout: {}, pins: pins)
//       RootView(hasICloud: true, authState: .Loading, login: {}, logout: {}, pins: pins)
//       RootView(hasICloud: true, authState: .LoggedOut, login: {}, logout: {}, pins: pins)
//     }
//       .previewLayout(.sizeThatFits)
//     Group {
//       RootView(hasICloud: true, authState: .LoggedIn(user), login: {}, logout: {}, pins: pins)
//     }
//       .previewLayout(.device)
//   }
// }
