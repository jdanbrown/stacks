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

  let persistentContainer: NSPersistentCloudKitContainer
  var managedObjectContext: NSManagedObjectContext { return persistentContainer.viewContext }

  init(preview: Bool = false) {
    log.info()

    // Make NSPersistentCloudKitContainer with name of .xcdatamodeld
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    persistentContainer = NSPersistentCloudKitContainer(name: "Model")

    // Don't persist saves in Previews
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    if preview {
      persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    // Both agree on this
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    persistentContainer.loadPersistentStores { storeDescription, error in
      if let error = error {
        fatalError("\(error)")
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
    persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

    // Observe remote change notifications
    //  - Example
    //    - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    //  - Docs
    //    - https://developer.apple.com/documentation/coredata/nspersistentstoredescription/1640574-setoption
    //    - https://developer.apple.com/documentation/coredata/nspersistentstorecoordinator
    //    - https://developer.apple.com/documentation/coredata/core_data_constants
    //  - TODO Is this working? -- onRemoteChange didn't log when I created a CorePin in the web console (using the blue plus icon)
    //    - Update: Yes, I think it's working
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

    // // XXX Insert some junk data, to test local/cloud sync
    // //  - Ok this is working: https://icloud.developer.apple.com/dashboard/database/teams/6S8S88RYPG/containers/iCloud.org.jdanbrown.stacks/environments/DEVELOPMENT/records?using=fetchChanges&database=private&zone=_com.apple.coredata.cloudkit.zone%3A_90b123e5f9d07fb5fc4ea4dfb7d19705%3AREGULAR_CUSTOM_ZONE
    // log.warning("Inserting junk data")
    // let now = NSDate().timeIntervalSince1970
    // let junk0 = CorePin(context: persistentContainer.viewContext)
    // junk0.url = URL(string: "http://junk.one/\(now)")
    // junk0.title = "Junk One - \(now)"
    // junk0.tags = "tag-0,tag-1"
    // save()

  }

  func save() {
    log.info()
    saveWith(context: managedObjectContext)
  }

  func saveWith(context: NSManagedObjectContext) {
    log.info()
    if context.hasChanges {
      log.info("Saving: hasChanges[\(context.hasChanges)]")
      do {
        try context.save()
      } catch {
        log.error("Failed to save: \(error)")
      }
    }
  }

  // Observe remote change notifications
  //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
  //  - https://github.com/SchwiftyUI/OrderedList/blob/master/OrderedList/AppDelegate.swift
  @objc
  func onRemoteChange(notification: NSNotification) {
    log.info("notification[\(notification)]")
    // TODO In case we need to do anything on updates, beyond @State which will already update our Views
  }

  // Mock for previews
  static var preview: StorageProvider = {
    let storageProvider = StorageProvider(preview: true)

    let pin0 = CorePin(context: storageProvider.persistentContainer.viewContext)
    pin0.url = "http://foo.one"
    pin0.title = "Foo One"

    let pin1 = CorePin(context: storageProvider.persistentContainer.viewContext)
    pin1.url = "http://foo.two"
    pin1.title = "Foo Two"

    return storageProvider
  }()

}