import SwiftUI

struct PinListView: View {

  @EnvironmentObject var pinsModel: PinsModel

  var body: some View {
    List(pinsModel.pins) { pin in
      VStack(alignment: .leading) {
        Text(pin.url)
          .font(.title)
      }
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    PinListView()
  }
}
