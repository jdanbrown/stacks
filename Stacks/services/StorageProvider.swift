import Combine
import CoreData

// TODO Popup + exit button i/o fatalError
//  - e.g. run app on phone -> app dies without error msg -> run macos Console.app to see fatalError("Can't migrate schema in place")
//  - More immediate UX that doesn't require going back to laptop would be a popup with the error msg and an exit button

// TODO Decide codegen for CorePin / Pin, CoreTag / Tag
//  - https://developer.apple.com/documentation/coredata/modeling_data/generating_code
//  - TODO Follow this helpful example of wrapping CoreFoo with Foo
//    - https://www.hackingwithswift.com/books/ios-swiftui/one-to-many-relationships-with-core-data-swiftui-and-fetchrequest

// Based on:
//  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
//  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
class StorageProvider {

  let cloudKitSyncMonitor: CloudKitSyncMonitor
  var onCloudKitImportComplete: Future<Void, Never>?

  let persistentContainer: NSPersistentCloudKitContainer
  var viewContext: NSManagedObjectContext { return persistentContainer.viewContext }

  var awaitingFirstCloudKitImport: Bool = true

  var pinsModel: PinsModel? = nil

  var cancellables = Set<AnyCancellable>()

  init(cloudKitSyncMonitor: CloudKitSyncMonitor, preview: Bool = false) {
    log.info()

    // Set fields
    self.cloudKitSyncMonitor = cloudKitSyncMonitor

    // Make NSPersistentCloudKitContainer with name of .xcdatamodeld
    //  - Practical Core Data (p18)
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    persistentContainer = NSPersistentCloudKitContainer(name: "Model")

    // In Xcode Previews, use a throwaway store (no initial state + writes don't persist)
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    if preview {
      persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

  }

  func start() {
    log.info()

    // Listen to notifications from the CloudKit sync
    //  - Based on: https://github.com/ggruen/CloudKitSyncMonitor/blob/1.1.1/Sources/CloudKitSyncMonitor/SyncMonitor.swift#L404
    onCloudKitImportComplete = Future<Void, Never>() { promise in
      NotificationCenter.default
        .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
        .sink(receiveValue: { notification in
          if let ckEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
            log.info("NSPersistentCloudKitContainer.eventChangedNotification: ckEvent[\(ckEvent)]")
            // if (ckEvent.type == .import && ckEvent.succeeded) {...} // XXX Doesn't wait for export + better to encapsulate in cloudKitSyncMonitor
            if self.cloudKitSyncMonitor.syncStateSummary == .succeeded {
              DispatchQueue.main.async {
                // HACK Adding refreshAllObjects() for good measure, in case container->context sync is a source of inconsistency/races
                log.info("Forcing sync container->context: viewContext.refreshAllObjects()")
                self.viewContext.refreshAllObjects()
                self.onCloudKitImport(promise)
              }
            }
          }
        })
        .store(in: &self.cancellables)
    }

    // Load Core Data stores
    //  - Practical Core Data (p18, p35)
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    persistentContainer.loadPersistentStores { storeDescription, error in
      if let error = error {
        // TODO Handle errors more gracefully
        //  - Practical Core Data (p18-19)
        //    - "Note that I am not handling any errors that might occur when loading my persistent store. At this point
        //      in the book and in the context of this chapter, a failure to load the persistent store is a programming
        //      error and not a recoverable situation. When your app is in production there are various reasons for the
        //      persistent container to fail loading your persistent stores."
        fatalError("Failed to load Core Data store: \(error)")
      }
    }

    // Pick policy for how to merge on record conflict
    //  - https://developer.apple.com/documentation/coredata/nsmergepolicy/merge_policies
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    //  - TODO Change this to handle merges manually so we can union/max/join each field
    //    - Use Pins.merge(xs, ys)
    // persistentContainer.viewContext.mergePolicy = NSErrorMergePolicy                       // Raise error, handle manually in code
    persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy      // Remote overrides local, per field within the record
    // persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy  // Local overrides remote, per field within the record
    // persistentContainer.viewContext.mergePolicy = NSOverwriteMergePolicy                   // Local overrides remote, for the entire record
    // persistentContainer.viewContext.mergePolicy = NSRollbackMergePolicy                    // Remote overrides local, for the entire record

    // "Without this, changes will not be pulled down from the iCloud to your phone"
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    //  - TODO Add reference from Practical Core Data (cmd-f the pdf to remember where this was discussed)
    persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

    // Observe remote change notifications
    //  - Example
    //    - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    //  - Docs
    //    - https://developer.apple.com/documentation/coredata/nspersistentstoredescription/1640574-setoption
    //    - https://developer.apple.com/documentation/coredata/nspersistentstorecoordinator
    //    - https://developer.apple.com/documentation/coredata/core_data_constants
    guard let storeDescription = persistentContainer.persistentStoreDescriptions.first else {
      fatalError("Failed to retrieve persistentStoreDescription")
    }
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onRemoteChange),
      name: .NSPersistentStoreRemoteChange,
      object: nil
    )

  }

  func onCloudKitImport(_ promise: Future<Void, Never>.Promise) {
    log.info("awaitingFirstCloudKitImport[\(awaitingFirstCloudKitImport)]")
    if awaitingFirstCloudKitImport {
      fetchPinsFromCoreData() // Fetch 2/3 from Cloud Kit (after CloudKit sync)
      promise(.success(()))
    }
    awaitingFirstCloudKitImport = false
  }

  @objc
  func fetchPinsFromCoreData() {
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
        let corePins = try self.viewContext.fetch(req)
        log.info("Fetched corePins[\(corePins.count)]")
        self.pinsModel!.update(corePins: corePins)
      } catch {
        // TODO Show error msg to user
        log.error("Failed to fetch: \(error)")
      }
    }
  }

  func upsertPins(_ pins: [Pin]) {
    log.info("pins[\(pins.count)]")
    self.pinsModel!.batchUpsert(pins) // TODO Restore
    // self.pinsModel!.batchUpsert(Array(pins.sorted(key: { $0.createdAt }, desc: true))) // XXX Dev
    // self.pinsModel!.batchUpsert(Array(pins.sorted(key: { $0.createdAt }, desc: false)[..<min(2000, pins.count)])) // XXX Dev
    // self.pinsModel!.batchUpsert(pins.filter { $0.url.contains("stratechery.com") }) // XXX Dev
    // self.pinsModel!.batchUpsert(pins.filter { $0.url.contains("mikedp.com") }) // XXX Dev
    self.fetchPinsFromCoreData() // Fetch 3/3 from Pinboard/Firestore (on each new upsert)
  }

  func deleteAllPins() {
    let corePins = self.pinsModel!.corePins
    log.info("corePins[\(corePins.count)]")
    for corePin in corePins {
      viewContext.delete(corePin)
    }
    save(context: viewContext)
    self.fetchPinsFromCoreData() // Fetch 4/3 to reset to new empty state in the persistent store
  }

  // TODO Revisit after deleting Pinboard/Firestore -- we don't need it anywhere yet
  // func addObserverToLoadOnSave() {
  //   // Manually subscribe fetchPinsFromCoreData() to Core Data changes
  //   //  - "Normal" swiftui would put a @FetchRequest in a View and this would be handled automatically
  //   //  - But @FetchRequest _requires_ being inside a View, so we can't do that here (we're a ~Model thing)
  //   //  - Instead, manually subscribe to changes to the Core Data store and update self.corePins via fetchPinsFromCoreData()
  //   //    - https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
  //   //    - https://developer.apple.com/documentation/coredata/nsmanagedobjectcontext
  //   NotificationCenter.default.addObserver(
  //     self,
  //     selector: #selector(load),
  //     name: .NSManagedObjectContextDidSave,
  //     object: viewContext
  //   )
  // }

  // Observe remote change notifications
  //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
  //  - https://github.com/SchwiftyUI/OrderedList/blob/master/OrderedList/AppDelegate.swift
  @objc
  func onRemoteChange(notification: NSNotification) {
    log.info("notification[\(notification)]")
    // TODO In case we need to do anything on updates, beyond @State which will already update our Views
  }

  func saveViewContext() {
    log.info()
    save(context: viewContext)
  }

  func save(context: NSManagedObjectContext) {
    log.info()
    if context.hasChanges {
      log.info("Saving context[\(context)]: hasChanges[\(context.hasChanges)]")
      do {
        // Try to save all changes since the last save()
        try context.save()
        log.info("Saved context[\(context)]")
      } catch {
        // Rollback all changes since the last save()
        //  - Else subsequent saves will keep failing the same way
        //  - e.g. Core Data entity validation errors (e.g. nil value in required field, because lots of room between swift types and core data)
        //  - Practical Core Data (p28)
        log.error("Failed to save context[\(context)]: \(error)")
        context.rollback()
        log.error("Rolled back context[\(context)]")
      }
    }
  }

  func saveToBackup() throws -> (alreadyExists: Bool, backupDir: URL) {
    let backupName = Backup.backupName(pinsModel: pinsModel!)
    let backupDir = try Backup.backupsDir()
      .appendingPathComponent(backupName)
    if FileManager.default.fileExists(atPath: backupDir.path) {
      log.info("Skipping, no changes since last save: backupDir[\(backupDir)]")
      return (alreadyExists: true, backupDir: backupDir)
    } else {
      log.info("Saving (has changes): backupDir[\(backupDir)]")
      try Backup.save(backupDir, pins: pinsModel!.pins)
      return (alreadyExists: false, backupDir: backupDir)
    }
  }

  // NOTE This doesn't remove any existing data, just upserts all the backup data into it
  //  - If you need to clean out existing data, manually delete the app + reset the CloudKit env, then call this
  //  - Cleaning out existing data is tricky because of CloudKit, and we don't really need it, so I stopped trying to make it work
  func upsertFromBackup(backupDir: URL) throws {
    // Autosave before restore
    //  - Else we'll *lose* any active data that isn't in the version we're about to restore
    //  - This assumes saved backups are named deterministically, else this will create a mess of extraneous backups
    //    when switching back and forth
    let (alreadyExists, autosaveBackupDir) = try saveToBackup()
    log.info("Autosave: alreadyExists[\(alreadyExists)], autosaveBackupDir[\(autosaveBackupDir)]")
    // Load data
    let pins = try Backup.load(backupDir)
    // Upsert
    log.info("Upserting: pins[\(pins.count)] from backupDir[\(backupDir)]")
    upsertPins(pins)
  }

  func deleteAllState() throws -> (alreadyExists: Bool, backupDir: URL) {
    // Autosave before delete
    //  - Always be recoverable
    let (alreadyExists, autosaveBackupDir) = try saveToBackup()
    log.info("Autosave: alreadyExists[\(alreadyExists)], autosaveBackupDir[\(autosaveBackupDir)]")
    // Delete all state
    log.info("Wiping all state")
    deleteAllPins()
    // Return the autosave
    return (alreadyExists: alreadyExists, backupDir: autosaveBackupDir)
  }

  // Mock for previews
  static var preview: StorageProvider = {
    let storageProvider = StorageProvider(cloudKitSyncMonitor: CloudKitSyncMonitor(), preview: true)

    let pin0 = CorePin(context: storageProvider.persistentContainer.viewContext)
    pin0.url = "http://foo.one"
    pin0.title = "Foo One"

    let pin1 = CorePin(context: storageProvider.persistentContainer.viewContext)
    pin1.url = "http://foo.two"
    pin1.title = "Foo Two"

    return storageProvider
  }()

}
