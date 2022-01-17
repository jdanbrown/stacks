import SwiftUI

struct LoginView: View {

  var login: () async -> ()

  var body: some View {
    VStack {
      Button { Task { await login() }} label: {
        Text("Login with Google")
      }
    }
  }

}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(login: {})
  }
}
