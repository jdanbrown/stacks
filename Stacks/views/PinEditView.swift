import SwiftUI

struct PinEditView: View {

  let pin: Pin
  let dismiss: () -> ()

  // TODO Throwaway editable fields to use until we move our data model to CloudKit
  @State var url: String
  @State var title: String
  @State var tags: [String]
  @State var notes: String
  @State var isRead: Bool

  // Navigation
  @StateObject var navigation: AutoNavigationLinkModel = AutoNavigationLinkModel()

  init(pin: Pin, dismiss: @escaping () -> ()) {

    self.pin = pin
    self.dismiss = dismiss

    // TODO Throwaway editable fields to use until we move our data model to CloudKit
    _url    = State(initialValue: pin.url)
    _title  = State(initialValue: pin.title)
    _tags   = State(initialValue: pin.tags)
    _notes  = State(initialValue: pin.notes)
    _isRead = State(initialValue: pin.isRead)

  }

  var body: some View {
    ZStack {
      AutoNavigationLink(model: navigation)
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

        // In pinbot I used single-line TextField's for everything except notes, where I used a multi-line TextEditor
        //  - I don't think I like single-line... and this doesn't solve the multi-line issues with TextEditor anyway
        // Section {
        //   Group {
        //     TextField("a", text: .constant(url))
        //     TextField("b", text: .constant(title))
        //     TextField("c", text: .constant(tags.joined(separator: " ")))
        //     TextEditor(text: .constant(notes))
        //       .fixedSize(horizontal: false, vertical: true)
        //       .lineLimit(nil)
        //       .frame(maxHeight: 10000)
        //   }
        // }

        // Alternate approach: Pushpin shows text fields that you tap to edit in their own full-sized screen
        Section {
          Picker("isRead", selection: $isRead) {
            Text("Unread").tag(false)
            Text("Read").tag(true)
          }
            .pickerStyle(SegmentedPickerStyle())
          Group {
            (url == ""
              ? Text("URL").foregroundColor(.gray)
              : Text(url)
            )
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                navigation.push(UrlEditView(url: $url).navigationTitle("URL"))
              }
            (title == ""
              ? Text("Title").foregroundColor(.gray)
              : Text(title)
            )
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                navigation.push(TitleEditView(title: $title).navigationTitle("Title"))
              }
            (tags == []
              ? Text("Tags").foregroundColor(.gray)
              : Text(tags.joined(separator: " "))
            )
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                navigation.push(TagsEditView(tags: $tags).navigationTitle("Tags"))
              }
            (notes == ""
              ? Text("Notes").foregroundColor(.gray)
              : Text(notes)
            )
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
              .contentShape(Rectangle())
              .onTapGesture {
                navigation.push(NotesEditView(notes: $notes).navigationTitle("Notes"))
              }
          }
        }

        Section(
          header: Text("Debug")
        ) {
          // https://www.datetimeformatter.com/how-to-format-date-time-in-swift/
          Group {
            Text("Created: \(pin.createdAt.format("yyyy MMM dd, h:mm a"))")
            Text("Modified: \(pin.modifiedAt.format("yyyy MMM dd, h:mm a"))")
            Text("Accessed: \(pin.accessedAt.format("yyyy MMM dd, h:mm a"))")
            Text("progressPageScroll: \(try! toJson(pin.progressPageScroll))")
            Text("progressPageScrollMax: \(try! toJson(pin.progressPageScrollMax))")
            Text("progressPdfPage: \(try! toJson(pin.progressPdfPage))")
            Text("progressPdfPageMax: \(try! toJson(pin.progressPdfPageMax))")
          }
            .foregroundColor(.gray)
        }

      }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
    }
  }

}

struct UrlEditView: View {
  @Binding var url: String
  var body: some View {
    TextEditor(text: $url)
  }
}

struct TitleEditView: View {
  @Binding var title: String
  var body: some View {
    TextEditor(text: $title)
  }
}

struct TagsEditView: View {
  @Binding var tags: [String]
  var body: some View {
    // TextEditor(text: ...)
    Text(tags.joined(separator: " "))
  }
}

struct NotesEditView: View {
  @Binding var notes: String
  var body: some View {
    TextEditor(text: $notes)
  }
}

// // Copy/paste: https://stackoverflow.com/a/61002589/397334
// func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
//   Binding(
//     get: { lhs.wrappedValue ?? rhs },
//     set: { lhs.wrappedValue = $0 }
//   )
// }

// TODO Update for Core Data
// struct PinEditView_Previews: PreviewProvider {
//   static var previews: some View {
//     let pins = Pin.previewPins
//     Group {
//       NavWrap { PinEditView(pin: pins[0], dismiss: {}) }
//       ForEach(pins[0..<3]) { pin in
//         PinEditView(pin: pin, dismiss: {})
//       }
//     }
//       .previewLayout(.sizeThatFits)
//   }
// }
