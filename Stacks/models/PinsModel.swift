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

  init(storageProvider: StorageProvider) {
    self.storageProvider = storageProvider
  }

  func update(corePins: [CorePin]) {
    log.info("corePins[\(corePins.count)]")
    self.corePins = corePins
    self.pins = self.corePins.map { $0.toPin() }
  }

  // Do a simplistic fetch-and-write for every pin in the batch
  //  - Performance won't matter after we drop Pinboard/Firestore because nothing will do giant batch upserts anymore
  //  - And it seems to run fast enough in practice anyway
  func batchUpsert(_ pins: [Pin]) {
    // Use main thread to avoid weird concurrency errors
    //  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
    //  - https://developer.apple.com/documentation/coredata/using_core_data_in_the_background
    //  - https://cocoacasts.com/three-common-core-data-mistakes-to-avoid
    //  - I previously tried storageProvider.persistentContainer.performBackgroundTask, but that crashed with "all that is left to us is honor"
    //    - https://stackoverflow.com/questions/41176098/is-this-a-valid-way-of-debugging-coredata-concurrency-issues
    DispatchQueue.main.async {
      let viewContext = self.storageProvider.viewContext
      log.info("pins[\(pins.count)]")
      for pin in pins {
        if let corePin = self._fetchCorePin(url: pin.url) {
          self._update(corePin, pin)
        } else {
          self._insert(viewContext, pin)
        }
        self.storageProvider.save(context: viewContext)
      }
      log.info("Done: pins[\(pins.count)]")
    }
  }

  private func _fetchCorePin(url: String) -> CorePin? {
    let req = CorePin.fetchRequest()
    req.predicate = NSPredicate(format: "%K = %@", #keyPath(CorePin.url), url)
    do {
      log.info("Fetching req[\(req)]")
      let corePins = try self.storageProvider.viewContext.fetch(req)
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
    let merged = Pins.merge(corePin.toPin(), pin)
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

}
