import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// Based on:
//  - https://capps.tech/blog/read-files-with-documentpicker-in-swiftui
//  - https://gist.github.com/MentalN/d4d2647aedd761831eeaf1450c299887
//  - https://github.com/markrenaud/FilePicker/blob/main/Sources/FilePicker/FilePickerUIRepresentable.swift
struct DocumentPicker: UIViewControllerRepresentable {

  let forOpeningContentTypes: [UTType]
  let allowsMultipleSelection: Bool
  let directoryURL: URL?
  let onPicked: (_ urls: [URL]) -> Void

  init(
    forOpeningContentTypes: [UTType],
    allowsMultipleSelection: Bool,
    directoryURL: URL?,
    onPicked: @escaping (_ urls: [URL]) -> Void
  ) {
    self.forOpeningContentTypes = forOpeningContentTypes
    self.allowsMultipleSelection = allowsMultipleSelection
    self.directoryURL = directoryURL
    self.onPicked = onPicked
  }

  func makeCoordinator() -> DocumentPicker.Coordinator {
    return DocumentPicker.Coordinator(parent: self)
  }

  func makeUIViewController(
    context: UIViewControllerRepresentableContext<DocumentPicker>
  ) -> UIDocumentPickerViewController {
    let controller = UIDocumentPickerViewController(
      forOpeningContentTypes: forOpeningContentTypes,
      asCopy: false
    )
    controller.allowsMultipleSelection = allowsMultipleSelection
    controller.directoryURL = directoryURL
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(
    _ uiViewController: DocumentPicker.UIViewControllerType,
    context: UIViewControllerRepresentableContext<DocumentPicker>
  ) {
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {

    let parent: DocumentPicker

    init(parent: DocumentPicker) {
      self.parent = parent
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      parent.onPicked(urls)
    }

  }

}
