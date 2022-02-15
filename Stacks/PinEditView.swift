import SwiftUI

struct PinEditView: View {

  let pin: Pin
  let dismiss: () -> ()

  var body: some View {
    Form {
      // TODO Why a bunch of vertical space here?

      Section(
        header: HStack {
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }
      ) {
        Picker("isRead", selection: .constant(pin.isRead)) {
          Text("Unread").tag(false)
          Text("Read").tag(true)
        }
          .pickerStyle(SegmentedPickerStyle())
        Group {
          TextEditor(text: .constant(pin.url))
          TextEditor(text: .constant(pin.title))
          TextEditor(text: .constant(pin.tags.joined(separator: " ")))
          TextEditor(text: .constant(pin.notes))
        }
          .fixedSize(horizontal: false, vertical: true)
          // .fixedSize(horizontal: true, vertical: false)
          // .lineLimit(1)
          // .lineLimit(nil)
          // .frame(maxHeight: 80)
          // .border(.black)
      }
        .headerProminence(.increased)

      Section {
        Text("Created: \(  try! toJson(pin.createdAt))")
        Text("Modified: \( try! toJson(pin.modifiedAt))")
        Text("Accessed: \( try! toJson(pin.accessedAt))")
      }

      Section {
        Text("progressPageScroll: \(    try! toJson(pin.progressPageScroll))")
        Text("progressPageScrollMax: \( try! toJson(pin.progressPageScrollMax))")
        Text("progressPdfPage: \(       try! toJson(pin.progressPdfPage))")
        Text("progressPdfPageMax: \(    try! toJson(pin.progressPdfPageMax))")
      }

    }
  }

}

struct PinEditView_Previews: PreviewProvider {
  static var previews: some View {
    let pins = Pin.previewPins
    Group {
      ForEach(pins[0..<3]) { pin in
        PinEditView(pin: pin, dismiss: {})
      }
    }
      .previewLayout(.sizeThatFits)
  }
}
