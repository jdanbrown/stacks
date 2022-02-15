import SwiftUI

// TODO TODO PinEditView
struct PinEditView: View {

  let pin: Pin
  @Binding var showEditSheet: Bool

  var body: some View {
      Form {
        // TODO Why a bunch of vertical space here?

        Section(
          header: HStack {
            Spacer()
            Button(action: { showEditSheet.toggle() }) {
              Image(systemName: "xmark")
            }
          }
        ) {
          Picker("isRead", selection: .constant(pin.isRead)) {
            Text("Unread").tag(false)
            Text("Read").tag(true)
          }
            .pickerStyle(SegmentedPickerStyle())
          TextEditor(text: .constant(pin.url))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
          TextEditor(text: .constant(pin.title))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
          TextEditor(text: .constant(pin.tags.joined(separator: " ")))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
          TextEditor(text: .constant(pin.notes))
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
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
    let pin = pins[0]
    Group {
      PinEditView(pin: pin, showEditSheet: .constant(false))
    }
      .previewLayout(.sizeThatFits)
  }
}
