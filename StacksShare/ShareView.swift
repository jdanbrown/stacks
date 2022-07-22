import Combine
import SwiftUI
import XCGLogger

func initShareExtension() {
  initLogging()
}

class ShareModel {

  let cloudKitSyncMonitor: CloudKitSyncMonitor
  let hasICloud: Bool
  let storageProvider: StorageProvider

  let pinsModel: PinsModel

  var cancellables = Set<AnyCancellable>()

  init() {

    self.cloudKitSyncMonitor = CloudKitSyncMonitor()
    self.cloudKitSyncMonitor.start()

    // Check if the user is logged into iCloud, else we'll refuse to load (in RootView, with a helpful error msg)
    //  - https://developer.apple.com/documentation/foundation/nsfilemanager/1408036-ubiquityidentitytoken
    //    - TODO Use `accountStatus() async` instead, as per those docs
    //      - https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus
    //    - TODO Don't require user to restart app after logging in
    //      - This will require the same async handling as the previous bullet
    //  - If we don't _explicitly_ check iCloud, then NSPersistentCloudKitContainer will silently fail to sync and log uncatchable errors
    //    - https://stackoverflow.com/questions/59138880/nspersistentcloudkitcontainer-how-to-check-if-data-is-synced-to-cloudkit
    self.hasICloud = FileManager.default.ubiquityIdentityToken != nil

    // StorageProvider for CloudKit + Core Data
    //  - Touch to init (lazy static let)
    self.storageProvider = StorageProvider(cloudKitSyncMonitor: cloudKitSyncMonitor)
    self.storageProvider.start()

    // PinsModel (Core Data)
    let pinsModel = PinsModel(storageProvider: storageProvider)
    storageProvider.pinsModel = pinsModel // HACK Cyclic dependency

    // Set fields
    self.pinsModel = pinsModel

  }

  func fetch(url: URL, onComplete: @escaping (_ corePin: CorePin?) -> ()) {
    log.info("url[\(url)]")
    storageProvider.onCloudKitImportComplete!
      .sink { _ in
        let corePin = self.pinsModel.fetchCorePin(self.storageProvider.viewContext, url: url.absoluteString)
        onComplete(corePin)
      }
      .store(in: &cancellables)
  }

}

struct ShareView: View {

  @ObservedObject var pinsModel: PinsModel
  @ObservedObject var cloudKitSyncMonitor: CloudKitSyncMonitor
  let corePin: CorePin?
  var pin: Pin? { return corePin?.toPin() }

  var body: some View {
    VStack {

      // XXX Dev: To observe cloudkit sync
      // Image(systemName: cloudKitSyncMonitor.syncStateSummary.symbolName)
      //   .foregroundColor(cloudKitSyncMonitor.syncStateSummary.symbolColor)
      //   .font(.body)

      if let pin = pin {

        // realPinView(Pin.previewPins.first!) // Mock pin
        // PinView(pin: pin, navigationPushTag: { tag in () }) // Real pin
        PinEditView(
          pin: pin,
          pinsModel: pinsModel,
          onSave: { pinsModel.storageProvider.fetchPinsFromCoreData() } // Fetch 6/3 on PinEditView save
        )

      } else {
        // TODO Add new pin
        //  - Create new CorePin(url) in ShareViewController
        //  - Pass into ShareView
        //  - Don't .save() the context until done (else we'll accumulate un-done pins)
        Text("pin=nil")
      }
    }
  }

}
