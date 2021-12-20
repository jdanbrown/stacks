import SwiftUI

struct PinListView: View {

  @EnvironmentObject var user: User
  @EnvironmentObject var pins: Obs<[Pin]>

  var body: some View {
    VStack {
      Text("PinList (\(pins.value.count) pins)")
      List(pins.value) { pin in
        VStack(alignment: .leading) {
          Text(pin.title)
          Text(pin.url)
            .font(.caption)
          HStack {
            ForEach(pin.tags, id: \.self) {
              Text($0)
                .font(.caption)
            }
          }
          Text(pin.notes)
        }
      }
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    let user = User(
      uid: "user_0",
      displayName: "Bob",
      email: "bob@gmail.com",
      photoURL: nil
    )
    let pins = Obs([
      Pin(
        id: "pin_0",
        url: "url_0",
        title: "title_0",
        tags: ["tag-0a", "tag-0b"],
        notes: "notes_0"
      ),
      Pin(
        id: "pin_1",
        url: "url_1",
        title: "title_1",
        tags: ["tag-1a", "tag-1b"],
        notes: "notes_1"
      ),
    ])
    PinListView()
      .environmentObject(user)
      .environmentObject(pins)
  }
}
