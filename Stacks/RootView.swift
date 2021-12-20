import SwiftUI

struct RootView: View {

  @EnvironmentObject var auth: AuthService

  var body: some View {
    VStack {
      if auth.loading {
        ProgressView()
      } else if auth.user == nil {
        LoginView()
      } else {
        VStack {
          Button { Task { await auth.logout() }} label: {
            Text("Logout: \(auth.user!.email ?? "[no email]")")
          }
          PinListView()
            .environmentObject(auth.user!)
        }
      }
    }
  }

}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
