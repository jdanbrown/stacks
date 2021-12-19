import SwiftUI

struct PinListView: View {

  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var pinsModel: PinsModel

  var body: some View {
    VStack {
      Text("PinList (\(pinsModel.pins.count) pins)")

      Button { Task { await auth.logout() }} label: {
        let email: String = auth.user?.email ?? "[no user/email]"
        Text("Logout: \(email)")
      }

      List(pinsModel.pins) { pin in
        VStack(alignment: .leading) {
          Text(pin.url)
            // .font(.title)
            .font(.body)
        }
      }

    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    // TODO Put mock [Pin] data here
    //  - How to mock out pinsModel in a sustainable way?
    PinListView()
  }
}
