import SwiftUI

struct PinListView2: View {

  var pins: [Pin]

  var body: some View {
    VStack {
      Text("PinList (\(pins.count) pins)")

      // TODO logout
      // Button { Task { await auth.logout() }} label: {
      //   let email: String = auth.user?.email ?? "[no user/email]"
      //   Text("Logout: \(email)")
      // }

      List(pins) { pin in
        VStack(alignment: .leading) {
          Text(pin.url)
            // .font(.title)
            .font(.body)
        }
      }

    }
  }

}

struct PinListView2_Previews: PreviewProvider {
  static var previews: some View {
    // TODO Put mock [Pin] data here
    //  - How to mock out pinsModel in a sustainable way?
    PinListView2(pins: [
    ])
  }
}
