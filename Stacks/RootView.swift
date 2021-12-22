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
          VStack {
            Button { Task { await logout() }} label: {
              Text("Logout: \(user.email ?? "[no email]")")
            }
            PinListView(
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
    let user = User.example0
    RootView(authState: .Loading, login: {}, logout: {}, pins: [])
      .previewLayout(.sizeThatFits)
    RootView(authState: .LoggedOut, login: {}, logout: {}, pins: [])
      .previewLayout(.sizeThatFits)
    RootView(authState: .LoggedIn(user), login: {}, logout: {}, pins: [])
      .previewLayout(.sizeThatFits)
  }
}
