import CoreData

// TODO Decide codegen for CorePin / Pin, CoreTag / Tag
//  - https://developer.apple.com/documentation/coredata/modeling_data/generating_code

// TODO onChange(of: scenePhase) -> save()
//  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui

// Based on:
//  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
//  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
class PersistenceController {

  // Singleton
  static let shared = PersistenceController()

  let container: NSPersistentCloudKitContainer

  init(preview: Bool = false) {
    log.info()

    // Make NSPersistentCloudKitContainer with name of .xcdatamodeld
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    container = NSPersistentCloudKitContainer(name: "Model")

    // Don't persist saves in Previews
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    if preview {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    // Both agree on this
    //  - https://www.hackingwithswift.com/quick-start/swiftui/how-to-configure-core-data-to-work-with-swiftui
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    container.loadPersistentStores { storeDescription, error in
      if let error = error {
        fatalError("Error: \(error.localizedDescription)")
      }
    }

    // On conflict, merge: by field + local overrides remote
    //  - https://developer.apple.com/documentation/coredata/nsmergepolicy/merge_policies
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    // "Without this, changes will not be pulled down from the iCloud to your phone"
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    container.viewContext.automaticallyMergesChangesFromParent = true

    // Observe remote change notifications
    //  - https://schwiftyui.com/swiftui/using-cloudkit-in-swiftui
    guard let storeDescription = container.persistentStoreDescriptions.first else {
      fatalError("###\(#function): Failed to retrieve persistentStoreDescription")
    }
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.onRemoteChange),
      name: .NSPersistentStoreRemoteChange,
      object: nil
    )

    // TODO HACK Insert some junk data, to test local/cloud sync
    //  - Ok this is working: https://icloud.developer.apple.com/dashboard/database/teams/6S8S88RYPG/containers/iCloud.org.jdanbrown.stacks/environments/DEVELOPMENT/records?using=fetchChanges&database=private&zone=_com.apple.coredata.cloudkit.zone%3A_90b123e5f9d07fb5fc4ea4dfb7d19705%3AREGULAR_CUSTOM_ZONE
    log.warning("Inserting junk data")
    let now = NSDate().timeIntervalSince1970
    let junk0 = CorePin(context: container.viewContext)
    junk0.url = URL(string: "http://junk.one/\(now)")
    junk0.title = "Junk One - \(now)"
    save()

  }

  func save() {
    log.info()
    let context = container.viewContext
    if context.hasChanges {
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
  }

  // Mock controller for previews
  static var preview: PersistenceController = {
    let controller = PersistenceController(preview: true)

    let pin0 = CorePin(context: controller.container.viewContext)
    pin0.url = URL(string: "http://foo.one")
    pin0.title = "Foo One"

    let pin1 = CorePin(context: controller.container.viewContext)
    pin1.url = URL(string: "http://foo.two")
    pin1.title = "Foo Two"

    return controller
  }()

}
