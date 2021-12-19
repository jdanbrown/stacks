import SwiftUI

struct LoginView: View {

  @EnvironmentObject var auth: AuthService

  var body: some View {
    VStack {
      Text("Login")
      Button { Task { await auth.login() }} label: {
        Text("Login with Google")
      }
    }
  }

}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView()
  }
}
