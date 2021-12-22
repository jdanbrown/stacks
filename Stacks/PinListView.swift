import SwiftUI

struct PinListView: View {

  var user: User
  var pins: [Pin]

  var body: some View {
    VStack {
      Text("PinList (\(pins.count) pins)")
      List(pins) { pin in
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
    let user = User.example0
    let pins = [
      Pin.ex0,
      Pin.ex1,
      Pin.ex1,
      Pin.ex0,
    ]
    PinListView(
      user: user,
      pins: pins
    )
  }
}
