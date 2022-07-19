import CoreData
import SwiftUI
import XCGLogger

extension CorePin {

  var tagsList: [String] {
    // TODO Cache
    return Tags.decode(tags ?? "")
  }

  func toPin() -> Pin {
    return Pin(
      url: self.url ?? "[null-url]",
      tombstone: self.tombstone,
      title: self.title ?? "[null-title]",
      tags: Tags.decode(self.tags ?? "[null-tags]"),
      notes: self.notes ?? "[null-notes]",
      createdAt: self.createdAt ?? Date.zero,
      modifiedAt: self.modifiedAt ?? Date.zero,
      accessedAt: self.accessedAt ?? Date.zero, // TODO Rename accessedAt -> openedAt after we delete Firestore (else confusing json compat)
      isRead: self.isRead,
      progressPageScroll: 0, // TODO
      progressPageScrollMax: 0, // TODO
      progressPdfPage: 0, // TODO
      progressPdfPageMax: 0 // TODO
    )
  }

  // Override NSManagedObject.description to not include newlines
  //  - Else log filtering in xcode is impossible, because you don't get complete lines
  override public var description: String {
    return super.description.replacingOccurrences(of: #"\s*\n\s*"#, with: " ", options: [.regularExpression])
  }

}
