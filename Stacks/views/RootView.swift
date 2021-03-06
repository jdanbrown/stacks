import SwiftUI

struct RootView: View {

  let storageProvider: StorageProvider
  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool
  var authState: AuthState
  var login: () async -> ()
  var logout: () async -> ()
  var pinsModel: PinsModel
  var pinsModelPinboard: PinsModelPinboard

  var body: some View {
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
                storageProvider: storageProvider,
                cloudKitSyncMonitor: cloudKitSyncMonitor,
                logout: logout,
                user: user,
                pinsModel: pinsModel,
                pinsModelPinboard: pinsModelPinboard
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
