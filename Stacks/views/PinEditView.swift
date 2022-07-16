import SwiftUI

struct PinEditView: View {

  @Environment(\.presentationMode) var presentationMode

  let pin: Pin
  let pinsModel: PinsModel
  let onSave: () -> ()

  @State var _isStateInitialized = false
  @State var url: String = ""
  @State var title: String = ""
  @State var tags: [String] = []
  @State var notes: String = ""
  @State var isRead: Bool = false

  // Navigation
  @StateObject var navigation: AutoNavigationLinkModel = AutoNavigationLinkModel()

  init(pin: Pin, pinsModel: PinsModel, onSave: @escaping () -> ()) {
    self.pin = pin
    self.pinsModel = pinsModel
    self.onSave = onSave
  }

  func initStateTo(pin: Pin) {
    if !_isStateInitialized {
      log.info("pin[\(pin)]")
      setStateTo(pin: pin)
      _isStateInitialized = true
    }
  }

  func setStateTo(pin: Pin) {
    log.info("pin[\(pin)]")
    url    = pin.url
    title  = pin.title
    tags   = pin.tags
    notes  = pin.notes
    isRead = pin.isRead
  }

  func hasChanges() -> Bool {
    return pin != editedPin()
  }

  func editedPin(modifiedAt: Date? = nil) -> Pin {
    return Pin(
      url:                   self.url,
      tombstone:             pin.tombstone,
      title:                 self.title,
      tags:                  self.tags,
      notes:                 self.notes,
      createdAt:             pin.createdAt,
      modifiedAt:            modifiedAt ?? pin.modifiedAt,
      accessedAt:            pin.accessedAt,
      isRead:                self.isRead,
      progressPageScroll:    pin.progressPageScroll,
      progressPageScrollMax: pin.progressPageScrollMax,
      progressPdfPage:       pin.progressPdfPage,
      progressPdfPageMax:    pin.progressPdfPageMax
    )
  }

  func undoChanges() {
    log.info()
    setStateTo(pin: pin)
    assert(!hasChanges()) // This will fail if we forget to add new editable fields here
  }

  func saveChanges() {
    log.info()
    // Save
    pinsModel.upsert(editedPin(
      // Bump modifiedAt to now
      modifiedAt: Date()
    ))
    // Dismiss PinEditView
    self.presentationMode.wrappedValue.dismiss()
    // Let parent know to re-fetch
    onSave()
  }

  var body: some View {
    ZStack {
      AutoNavigationLink(model: navigation)
      Form {
        // TODO Why a bunch of vertical space here?

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

        // NOTE We want to get called on init, but this also gets called when a pushed view pops back to us
        //  - e.g. init triggers onAppear -> push TitleEditView -> pop -> triggers onAppear again (erp!)
        //  - Solution: Indirect through initStateTo so it can guard on a var
        .onAppear {
          initStateTo(pin: pin)
        }

        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(hasChanges())
        .navigationBarItems(
          leading: Group {
            if hasChanges() {
              Button {
                undoChanges()
              } label: {
                Text("Undo")
              }
            }
          },
          trailing: Group {
            if hasChanges() {
              Button {
                saveChanges()
              } label: {
                Text("Done").bold()
              }
            }
          }
        )
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
//       NavWrap { PinEditView(pin: pins[0]) }
//       ForEach(pins[0..<3]) { pin in
//         PinEditView(pin: pin)
//       }
//     }
//       .previewLayout(.sizeThatFits)
//   }
// }
