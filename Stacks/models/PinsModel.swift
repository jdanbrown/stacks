import Combine
import CoreData
import SwiftUI
import XCGLogger

class PinsModel: ObservableObject {

  // HACK Keep both corePins + pins
  //  - Passing corePins to a View doesn't update the View on e.g. tag changes, whereas passing pins does
  //    - I _think_ because NSManagedObject compares by .objectID (e.g. isEqual docs say it doesn't fault)
  //  - So pass pins to Views instead
  //  - And then keep corePins around to make edits/updates simple
  //    - Alternatively, fetchRequest on each update, but not sure whether that's more complicated (haven't tried it)
  //  - Didn't really find any great articles about this, but here's a suggestive one
  //    - https://stackoverflow.com/questions/71158884/swiftui-calling-coredata-in-observableobject
  @Published var corePins: [CorePin] = []
  @Published var pins: [Pin] = []

  let storageProvider: StorageProvider
  let pinsPublishers: [Published<[Pin]>.Publisher]

  private var cancellables: [Cancellable] = [] // Must retain all .sink return values else they get deinit-ed and silently .cancel-ed!

  init(
    storageProvider: StorageProvider,
    pinsPublishers: [Published<[Pin]>.Publisher]
  ) {
    self.storageProvider = storageProvider
    self.pinsPublishers = pinsPublishers

    // XXX Hmm, try doing this _after_ load() from CloudKit, to see if that fixes the duplicate-insert races
    // self.cancellables += pinsPublishers.map { pinsPublisher in
    //   pinsPublisher.receive(on: RunLoop.main).sink { pins in
    //     self.upsert(pins) // TODO Restore
    //     // self.upsert(Array(pins.sorted(key: { $0.createdAt }, desc: true))) // XXX Dev
    //     // self.upsert(Array(pins.sorted(key: { $0.createdAt }, desc: false)[..<min(2000, pins.count)])) // XXX Dev
    //     // self.upsert(pins.filter { $0.url.contains("stratechery.com") }) // XXX Dev
    //     // self.upsert(pins.filter { $0.url.contains("mikedp.com") }) // XXX Dev
    //   }
    // }

    // // Manually subscribe load() to Core Data changes
    // //  - "Normal" swiftui would put a @FetchRequest in a View and this would be handled automatically
    // //  - But @FetchRequest _requires_ being inside a View, so we can't do that here (we're a ~Model thing)
    // //  - Instead, manually subscribe to changes to the Core Data store and update self.corePins via load()
    // //    - https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
    // //    - https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
    // NotificationCenter.default.addObserver(
    //   self,
    //   selector: #selector(self.load),
    //   name: .NSManagedObjectContextDidSave,
    //   object: self.storageProvider.managedObjectContext
    // )

  }

  @objc
  func load() {
    // Stay on main thread else risk of EXC_BREAKPOINT when called via NotificationCenter.default.addObserver
    //  - https://stackoverflow.com/questions/59300223/violate-core-data-s-threading-contractexc-breakpoint-code-1-subcode-0x1f0ad1c8
    DispatchQueue.main.async {
      let req = CorePin.fetchRequest()
      req.sortDescriptors = [
        NSSortDescriptor(keyPath: \CorePin.createdAt, ascending: false),
        NSSortDescriptor(keyPath: \CorePin.url,       ascending: true),
      ]
      do {
        log.info("Fetching req[\(req)]")
        self.corePins = try self.storageProvider.managedObjectContext.fetch(req)
        log.info("Fetched corePins[\(self.corePins.count)]")
        self.pins = self.corePins.map { $0.toPin() }
      } catch {
        // TODO Show error msg to user
        log.error("Failed to fetch: \(error)")
      }
    }
  }

  func addObserverToLoadOnSave() {
    // Manually subscribe load() to Core Data changes
    //  - "Normal" swiftui would put a @FetchRequest in a View and this would be handled automatically
    //  - But @FetchRequest _requires_ being inside a View, so we can't do that here (we're a ~Model thing)
    //  - Instead, manually subscribe to changes to the Core Data store and update self.corePins via load()
    //    - https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
    //    - https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.load),
      name: .NSManagedObjectContextDidSave,
      object: self.storageProvider.managedObjectContext
    )
  }

  // XXX after we remove Pinboard/Firestore
  func loadPinsPublishers() {
    self.cancellables += pinsPublishers.map { pinsPublisher in
      pinsPublisher.receive(on: RunLoop.main).sink { pins in
        self.upsert(pins) // TODO Restore
        // self.upsert(Array(pins.sorted(key: { $0.createdAt }, desc: true))) // XXX Dev
        // self.upsert(Array(pins.sorted(key: { $0.createdAt }, desc: false)[..<min(2000, pins.count)])) // XXX Dev
        // self.upsert(pins.filter { $0.url.contains("stratechery.com") }) // XXX Dev
        // self.upsert(pins.filter { $0.url.contains("mikedp.com") }) // XXX Dev
      }
    }
  }

  // TODO TODO To avoid duplicate-insert races, try fetch-and-save for _every_ pin we upsert
  //  - Example
  //    - https://stackoverflow.com/questions/49485609/in-core-data-how-to-do-if-exists-update-else-insert-in-swift-4
  //  - I can't figure out how to fix the batch variant of upsert() below, so trying this instead
  //  - Performance won't matter after we drop Pinboard/Firestore because nothing will do giant batch upserts anymore
  //
  // TODO TODO WHAT THE FUCK How is this still creating duplicate inserts??
  //  - Repro: Erase CK + erase app -> load app (~1000 pins) -> erase app (keep CK) -> load app -> I just observed 1529 pins :/
  //  - Ugh
  //  - Step back, try again, at least I'm narrowing it down
  //
  func upsert(_ pins: [Pin]) {
    // Use main thread to avoid weird concurrency errors
    //  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
    //  - https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
    //  - https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
    //  - I previously tried storageProvider.container.performBackgroundTask, but that crashed with "all that is left to us is honor"
    //    - https://stackoverflow.com/questions/41176098/is-this-a-valid-way-of-debugging-coredata-concurrency-issues
    DispatchQueue.main.async {
      let context = self.storageProvider.managedObjectContext
      log.info("pins[\(pins.count)]")
      for pin in pins {
        if let corePin = self._fetchCorePin(url: pin.url) {
          self._update(corePin, pin)
        } else {
          self._insert(context, pin)
        }
        self.storageProvider.saveWith(context: context)
      }
      log.info("Done: pins[\(pins.count)]")
    }
  }

  private func _fetchCorePin(url: String) -> CorePin? {
    let req = CorePin.fetchRequest()
    req.predicate = NSPredicate(format: "url = %@", url)
    do {
      log.info("Fetching req[\(req)]")
      let corePins = try self.storageProvider.managedObjectContext.fetch(req)
      if corePins.count == 0 {
        log.info("Fetched no corePins")
        return nil
      } else {
        let corePin = corePins[0]
        if corePins.count == 1 {
          log.info("Fetched one corePin[\(corePin)]")
        } else {
          log.info("Fetched multiple corePins[\(corePins.count)], returning first corePin[\(corePin)]")
        }
        return corePin
      }
    } catch {
      // TODO Show error msg to user
      log.error("Failed to fetch: \(error)")
      return nil
    }
  }

  // func upsert(_ pins: [Pin]) {
  //   // Use main thread to avoid weird concurrency errors
  //   //  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
  //   //  - https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
  //   //  - https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
  //   //  - I previously tried storageProvider.container.performBackgroundTask, but that crashed with "all that is left to us is honor"
  //   //    - https://stackoverflow.com/questions/41176098/is-this-a-valid-way-of-debugging-coredata-concurrency-issues
  //   DispatchQueue.main.async {
  //     let context = self.storageProvider.managedObjectContext
  //     log.info("pins[\(pins.count)]")
  //     // If multiple pins have the same url, upsert into the first pin and (silently) ignore the rest
  //     //  - Leave it to the user to notice and manually clean up
  //     //  - This can potentially happen because Core Data doesn't provide an atomic upsert
  //     //    - https://stackoverflow.com/questions/49485609/in-core-data-how-to-do-if-exists-update-else-insert-in-swift-4
  //     //    - https://stackoverflow.com/questions/12374132/coredata-is-there-a-good-way-to-upsert-items
  //     //    - https://www.upbeat.it/upsert-in-core-data
  //     //      - Nice try, but CloudKit doesn't allow unique constraints
  //     let corePinsLookup = Dictionary(self.corePins.map { ($0.url, $0) }, uniquingKeysWith: { x, y in x })
  //     log.info("corePinsLookup[\(corePinsLookup.count)]")
  //
  //     // HACK Batch .save() calls into small groups of 100 because TOTAL FUCKING VOODOO
  //     //  - Calling NSManagedObjectContext.save() in batches of ~1000 causes weird nondeterministic duplicate writes
  //     //  - I observed this ~1/3 of the time on Simulator (laptop) when loading a highly overlapping set of ~1000 pins
  //     //    from Pinboard + Firestore on a second run of the app from empty state, i.e. after populating Core Data once
  //     //  - I synchronized everything on DispatchQueue.main, and I added logging to look for race conditions in my app
  //     //    data (e.g. corePins/corePinsLookup), but all app data would be properly synchronized and the duplicate
  //     //    inserts would still happen, with weird duplicate logging from CoreData/CloudKit itself, so I concluded the
  //     //    problem was somewhere down there (e.g. probably I'm _using_ CoreData/CloudKit incorrectly and don't know it)
  //     //  - Setting a batch size of 100 appears to avoid the issue, so... :shrug:
  //     //
  //     // TODO TODO Hmm, nope, tripped it again with batch size 100
  //     //  - Repro
  //     //    - Populate CloudKit with ~1000 records (from Pinboard/Firestore)
  //     //    - Wipe CoreData (by deleting app, but not resetting CloudKit env)
  //     //    - Start app -> ~2000 pins (instead of ~1000 pins)
  //     //  - Hypothesis
  //     //    - Pinboard/Firestore aren't racing with each other, but with CloudKit->CoreData
  //     //
  //     // for _pins in pins.chunked(size: 100) {...}
  //     for _pins in [pins] { // XXX Enable local code editing
  //       for pin in _pins {
  //         if let corePin = corePinsLookup[pin.url] {
  //           // HACK Use != to catch either side updating
  //           // HACK Drop one update if both sides get back to the same timestamp independently
  //           // if corePin.modifiedAt >= pin.modifiedAt {
  //           //   log.info("Skipping: corePin.modifiedAt[\(opt: corePin.modifiedAt)] >= pin.modifiedAt[\(pin.modifiedAt)]")
  //           // } else ...
  //           // if corePin.modifiedAt == pin.modifiedAt {
  //           //   log.info("Skipping: corePin.modifiedAt[\(opt: corePin.modifiedAt)] == pin.modifiedAt[\(pin.modifiedAt)]")
  //           // } else {
  //           //   self._update(corePin, pin)
  //           // }
  //           // Hmm, removing the check appears to just work, let's see if we can go with that
  //           self._update(corePin, pin)
  //         } else {
  //           self._insert(context, pin)
  //         }
  //       }
  //       self.storageProvider.saveWith(context: context)
  //     }
  //
  //     log.info("Done: pins[\(pins.count)]")
  //   }
  // }

  private func _insert(_ context: NSManagedObjectContext, _ pin: Pin) {
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
  private func _update(_ corePin: CorePin, _ pin: Pin) {
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
  //   let m = CorePin(context: storageProvider.managedObjectContext)
  //   // TODO Assign all the fields
  //   m.title = pin.title
  //   // ...
  //   storageProvider.save()
  // }

  // // TODO Call from callers
  // func update(_ pin: Pin) throws{
  //   log.info("pin[\(pin)]")
  //   if let mid = pin.managedObjectID {
  //     var m: CorePin?
  //     do {
  //       m = try storageProvider.managedObjectContext.existingObject(with: mid) as! CorePin?
  //     } catch {
  //       m = nil
  //     }
  //     if let m = m {
  //       // TODO Assign all the fiels
  //       m.title = pin.title
  //       // ...
  //       storageProvider.save()
  //     } else {
  //       throw SimpleError("Pin not found: pin[\(pin)]")
  //     }
  //   } else {
  //     log.error("Pin has no managedObjectID: pin[\(pin)]")
  //   }
  // }

}
