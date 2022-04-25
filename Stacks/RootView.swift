import SwiftUI

struct RootView: View {

  var authState: AuthState
  var login: () async -> ()
  var logout: () async -> ()
  var pins: [Pin]

  var body: some View {
    VStack {
      switch authState {
        case .Loading:
          ProgressView()
        case .LoggedOut:
          LoginView(login: login)
        case .LoggedIn(let user):
          NavWrap {
            PinListView(
              logout: logout,
              user: user,
              pins: pins
            )
          }
      }
    }
  }

}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    let user = User.previewUser0
    let pins = Pin.previewPins
    Group {
      RootView(authState: .Loading, login: {}, logout: {}, pins: pins)
      RootView(authState: .LoggedOut, login: {}, logout: {}, pins: pins)
    }
      .previewLayout(.sizeThatFits)
    Group {
      RootView(authState: .LoggedIn(user), login: {}, logout: {}, pins: pins)
    }
      .previewLayout(.device)
  }
}
