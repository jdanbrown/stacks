import SwiftUI

struct RootView: View {

  let storageProvider: StorageProvider
  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool
  // Used in Firebase auth, keeping for a bit in case it's a helpful to repurpose
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
        switch authState { // Used in Firebase auth, keeping for a bit in case it's a helpful to repurpose
          case .Loading:
            ProgressView()
          case .LoggedOut:
            LoginView(login: login)
          case .LoggedIn:
            NavWrap {
              PinListView(
                storageProvider: storageProvider,
                cloudKitSyncMonitor: cloudKitSyncMonitor,
                logout: logout,
                pinsModel: pinsModel,
                pinsModelPinboard: pinsModelPinboard
              )
            }
        }
      }
    }
  }

}

// Used in Firebase auth, keeping for a bit in case it's a helpful to repurpose
enum AuthState {
  case Loading
  case LoggedOut
  case LoggedIn
}

// TODO Update for Core Data
// struct RootView_Previews: PreviewProvider {
//   static var previews: some View {
//     let pins = Pin.previewPins
//     Group {
//       RootView(hasICloud: false, authState: .Loading, login: {}, logout: {}, pins: pins)
//       RootView(hasICloud: true, authState: .Loading, login: {}, logout: {}, pins: pins)
//       RootView(hasICloud: true, authState: .LoggedOut, login: {}, logout: {}, pins: pins)
//     }
//       .previewLayout(.sizeThatFits)
//     Group {
//       RootView(hasICloud: true, authState: .LoggedIn, login: {}, logout: {}, pins: pins)
//     }
//       .previewLayout(.device)
//   }
// }
