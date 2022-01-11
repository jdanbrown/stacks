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
            .font(.body)
          Text(pin.url)
            .font(.caption)
            .foregroundColor(Color.gray)
          HStack {
            ForEach(pin.tags, id: \.self) {
              Text($0)
                .font(.caption)
                .foregroundColor(Color.blue)
            }
          }
          Text(pin.notes)
            .font(.footnote)
          Text(showDate(pin.createdAt))
            .font(.caption)
            .foregroundColor(Color.gray)
        }
      }
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    let user = User.example0

    // let pins = [
    //   Pin.ex0,
    //   Pin.ex1,
    //   Pin.ex1,
    //   Pin.ex0,
    // ]

    // WOOOOOOO it works!
    //
    // TODO TODO Load .json from asset file in 'Preview Content'/ dir
    let pins: [Pin] = try! fromJson(loadAsset("preview-pins.json"))

    PinListView(
      user: user,
      pins: pins
    )
  }

}


// TODO TODO Load .json from asset file in 'Preview Content'/ dir
//  - https://medium.com/@keremkaratal/swiftui-exploiting-xcode-11-canvas-2fe46d66c3d8
func loadAsset(_ filename: String) -> Data {
  guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
    fatalError("Asset file not found: \(filename)")
  }
  do {
    let data = try Data(contentsOf: file)
    return data
  } catch {
    fatalError("Failed to read asset file[\(filename)] from main bundle: \(error)")
  }
}
