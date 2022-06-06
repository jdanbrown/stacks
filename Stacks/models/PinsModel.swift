import Combine
import CoreData
import SwiftUI
import XCGLogger

class PinsModel: ObservableObject {

  @Published var corePins = [CorePin]()
  // @Published var pins = [Pin]()

  let persistenceController: PersistenceController

  private var cancellables: [Cancellable] = [] // Must retain all .sink return values else they get deinit-ed and silently .cancel-ed!

  init(
    persistenceController: PersistenceController,
    pinsPublishers: [Published<[Pin]>.Publisher]
  ) {
    self.persistenceController = persistenceController
    self.cancellables += pinsPublishers.map { pinsPublisher in
      pinsPublisher.receive(on: RunLoop.main).sink { pins in
        self.upsert(pins) // TODO Restore
        // self.upsert(Array(pins[..<min(2, pins.count)])) // XXX Dev
        // self.upsert(pins.filter { $0.url.contains("stratechery.com") }) // XXX Dev
        // self.upsert(pins.filter { $0.url.contains("mikedp.com") }) // XXX Dev
      }
    }

    // TODO TODO Manually subscribe load() to Core Data changes
    //  - "Normal" swiftui would put a @FetchRequest in a View and this would be handled automatically
    //  - But @FetchRequest _requires_ being inside a View, so we can't do that here (we're a ~Model thing)
    //  - Instead, manually subscribe to changes to the Core Data store and update self.corePins via load()
    //    - https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
    //    - https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.load),
      name: .NSManagedObjectContextDidSave,
      object: self.persistenceController.managedObjectContext
    )

  }

  // TODO TODO Use swiftui @FetchRequest to make this correctly reactive -- hmm, how do do with Model instead of View?
  //  - Problem: Delete app state (keep cloudkit state) -> run app -> PinListView is empty
  //  - Cause: This load() happens before CloudKit syncs to Core Data -- logging says `Fetched corePins[0]`
  // Using:   https://www.hackingwithswift.com/read/38/5/loading-core-data-objects-using-nsfetchrequest-and-nssortdescriptor
  // Similar: https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-core-data-fetch-request-using-fetchrequest
  // Similar: https://www.hackingwithswift.com/quick-start/swiftui/how-to-limit-the-number-of-items-in-a-fetch-request
  @objc
  func load() {
    let req = CorePin.fetchRequest()
    req.sortDescriptors = [
      NSSortDescriptor(keyPath: \CorePin.createdAt, ascending: false),
      NSSortDescriptor(keyPath: \CorePin.url,       ascending: true),
    ]
    do {
      log.info("Fetching req[\(req)]")
      self.corePins = try persistenceController.managedObjectContext.fetch(req)
      log.info("Fetched corePins[\(corePins.count)]")
    } catch {
      // TODO Show error msg to user
      log.error("Failed to fetch: \(error)")
    }
  }

  func upsert(_ pins: [Pin]) {
    log.info("pins[\(pins.count)]")
    // NOTE If duplicate pins with same url, use the first pin and silently ignore the rest
    //  - This can happen because Core Data doesn't provide an atomic upsert
    //    - https://stackoverflow.com/questions/49485609/in-core-data-how-to-do-if-exists-update-else-insert-in-swift-4
    //    - https://stackoverflow.com/questions/12374132/coredata-is-there-a-good-way-to-upsert-items
    //    - https://www.upbeat.it/upsert-in-core-data
    //      - Nope, can't use unique constraints with CloudKit
    //  - If we end up with duplicate urls, then we leave it to the user to notice and manually clean things up
    let corePinsLookup = Dictionary(corePins.map { ($0.url, $0) }, uniquingKeysWith: { x, y in x })
    // TODO TODO Does avoiding this potential race condition solve the double writes?
    //  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
    // TODO TODO Now seeing the "all that is left to us is honor" crash from enabling `-com.apple.CoreData.ConcurrencyDebug 1`
    //  - https://stackoverflow.com/questions/41176098/is-this-a-valid-way-of-debugging-coredata-concurrency-issues
    //  - Next try: Use DispatchQueue.main.async
    //    - https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
    //    - https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
    // persistenceController.container.performBackgroundTask { context in
    DispatchQueue.main.async {
      let context = self.persistenceController.managedObjectContext // NOTE Use iff DispatchQueue.main.async
      for pin in pins {
        if let corePin = corePinsLookup[pin.url] {
          // HACK Use != to catch either side updating
          // HACK Drop one update if both sides get back to the same timestamp independently
          // if corePin.modifiedAt >= pin.modifiedAt {
          //   log.info("Skipping: corePin.modifiedAt[\(opt: corePin.modifiedAt)] >= pin.modifiedAt[\(pin.modifiedAt)]")
          // if corePin.modifiedAt == pin.modifiedAt {
          //   log.info("Skipping: corePin.modifiedAt[\(opt: corePin.modifiedAt)] == pin.modifiedAt[\(pin.modifiedAt)]")
          // } else {
          //   self._update(corePin, pin)
          // }
          // Hmm, removing the check appears to just work, let's see if we can go with that
          self._update(corePin, pin)
        } else {
          self._insert(context, pin)
        }
      }
      self.persistenceController.saveWith(context: context)
    }
  }

  func _insert(_ context: NSManagedObjectContext, _ pin: Pin) {
    log.info("pin[\(pin)]")
    let corePin = CorePin(context: context)
    corePin.tombstone  = pin.tombstone
    corePin.url        = pin.url
    corePin.title      = pin.title
    corePin.tags       = Tags.encode(pin.tags)
    corePin.notes      = pin.notes
    corePin.createdAt  = pin.createdAt
    corePin.modifiedAt = pin.modifiedAt
    corePin.accessedAt = pin.accessedAt
    corePin.isRead     = pin.isRead
  }

  // Idempotent
  func _update(_ corePin: CorePin, _ pin: Pin) {
    // TODO Do we need to manually detect writes to skip? Or will Core Data magically figure it out for us?
    log.info("corePin[\(corePin)], pin[\(pin)]")
    let merged = Pin.merge(corePin.toPin(), pin)
    assert(corePin.url == pin.url, "corePin.url[\(opt: corePin.url)] == pin.url[\(pin.url)]")
    corePin.tombstone             = merged.tombstone
    corePin.title                 = merged.title
    corePin.tags                  = Tags.encode(merged.tags)
    corePin.notes                 = merged.notes
    corePin.createdAt             = merged.createdAt
    corePin.modifiedAt            = merged.modifiedAt
    corePin.accessedAt            = merged.accessedAt
    corePin.isRead                = merged.isRead
    // corePin.progressPageScroll    = merged.progressPageScroll
    // corePin.progressPageScrollMax = merged.progressPageScrollMax
    // corePin.progressPdfPage       = merged.progressPdfPage
    // corePin.progressPdfPageMax    = merged.progressPdfPageMax
  }

  // func upsert(_ pins: [Pin]) {
  //   log.info("pins[\(pins.count)]")
  //   self.pins = self.merge(self.pins, pins)
  //   // TODO Call upsert(pin) for all pins with a diff in diffs
  //   //  - Hmm, is this actually a good way to determine which pins need upserts?
  // }

  // func merge(_ xs: [Pin], _ ys: [Pin]) -> [Pin] {
  //   let (zs, diffs) = Pins.merge(xs, ys)
  //   // TODO Store the PinDiff's
  //   //  - Just printing them for now
  //   log.info("diffs[\(diffs.count)]")
  //   for (i, diff) in diffs.enumerated() {
  //     print("  diff[\(i)].before")
  //     for x in diff.before {
  //       print("    \(x)")
  //     }
  //     print("  diff[\(i)].after")
  //     print("    \(diff.after)")
  //   }
  //   return zs
  // }

  // // TODO Call from callers
  // //  - PinEditView
  // //  - upsert(pins)
  // func upsert(_ pin: Pin) throws {
  //   log.info("pin[\(pin)]")
  //   // TODO Hmm, is this actually a good way to detect insert-vs-update, or should we drop down to managedObjectContext.existingObject?
  //   if !self.pins.map({ $0.url} ).contains(pin.url) {
  //     self.insert(pin)
  //   } else {
  //     try self.update(pin)
  //   }
  // }

  // // TODO Call from callers
  // func insert(_ pin: Pin) {
  //   log.info("pin[\(pin)]")
  //   let m = CorePin(context: persistenceController.managedObjectContext)
  //   // TODO Assign all the fields
  //   m.title = pin.title
  //   // ...
  //   persistenceController.save()
  // }

  // // TODO Call from callers
  // func update(_ pin: Pin) throws{
  //   log.info("pin[\(pin)]")
  //   if let mid = pin.managedObjectID {
  //     var m: CorePin?
  //     do {
  //       m = try persistenceController.managedObjectContext.existingObject(with: mid) as! CorePin?
  //     } catch {
  //       m = nil
  //     }
  //     if let m = m {
  //       // TODO Assign all the fiels
  //       m.title = pin.title
  //       // ...
  //       persistenceController.save()
  //     } else {
  //       throw SimpleError("Pin not found: pin[\(pin)]")
  //     }
  //   } else {
  //     log.error("Pin has no managedObjectID: pin[\(pin)]")
  //   }
  // }

}
