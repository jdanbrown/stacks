import SwiftUI

struct PinEditView: View {

  let pin: Pin
  let dismiss: () -> ()

  var body: some View {
    Form {
      // TODO Why a bunch of vertical space here?

      // Text("Edit")
      //   .background(Color.gray.opacity(0))

      // Section {
      //   HStack {
      //     Spacer()
      //     Text("Edit")
      //     Spacer()
      //     // Button(action: { dismiss() }) {
      //     //   // Image(systemName: "xmark")
      //     //   Text("Done")
      //     // }
      //   }
      // }

      // Section(
      //   header: HStack {
      //     Spacer()
      //     Text("Edit")
      //     Spacer()
      //     // Button(action: { dismiss() }) {
      //     //   // Image(systemName: "xmark")
      //     //   Text("Done")
      //     // }
      //   }
      // ) {

      // Problem: Can't figure out how to stack multiple multi-line TextEditor's in the same view
      //  - e.g. .fixedSize(horizontal: false, vertical: true) stops working with >1 TextEditor
      //  - e.g. Adding .frame(maxHeight: 10000) doesn't help
      //  - e.g. Adding .lineLimit(nil) doesn't help
      //  - Tip: add .border(.black) to debug frame size
      //  - TODO TODO Instead, tap to open a new overlay with TextEditor
      //    - This is how Pushpin does it and it works well enough

      Section {
        Group {
          Text(pin.url)
        }
        Picker("isRead", selection: .constant(pin.isRead)) {
          Text("Unread").tag(false)
          Text("Read").tag(true)
        }
          .pickerStyle(SegmentedPickerStyle())
      }

      Section {
        Group {
          Text(pin.title)
          Text(pin.tags.joined(separator: " "))
          Text(pin.notes)
        }
      }

      Section(
        header: Text("Timestamps")
      ) {
        // https://www.datetimeformatter.com/how-to-format-date-time-in-swift/
        Text("Created: \(pin.createdAt.format("yyyy MMM dd, h:mm a"))")
        Text("Modified: \(pin.modifiedAt.format("yyyy MMM dd, h:mm a"))")
        Text("Accessed: \(pin.accessedAt.format("yyyy MMM dd, h:mm a"))")
      }

      Section(
        header: Text("Debug")
      ) {
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
