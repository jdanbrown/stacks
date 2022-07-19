// Based on
//  - https://developer.apple.com/documentation/foundation/app_extension_support/supporting_suggestions_in_your_app_s_share_extension
//  - https://diamantidis.github.io/2020/01/11/share-extension-custom-ui
//  - https://stackoverflow.com/questions/58490571/can-we-use-swiftui-to-build-ios-today-extension
//  - https://airlist.app/blog/swiftui-share-extension

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import XCGLogger

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    initShareExtension()

    self.setViewControllers(
      [ShareViewController()],
      animated: false
    )

  }

}

class ShareViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Docs
    //  - https://developer.apple.com/documentation/foundation/nsextensioncontext
    //  - https://developer.apple.com/documentation/foundation/nsextensionitem
    //  - https://developer.apple.com/documentation/foundation/nsitemprovider
    print("XXX 0")
    if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
      print("XXX 1")
      if let attachment = (extensionItem.attachments ?? []).first {
        print("XXX 2")
        let contentType = UTType.url
        if attachment.hasItemConformingToTypeIdentifier(contentType.identifier) {
          attachment.loadItem(forTypeIdentifier: contentType.identifier, options: nil, completionHandler: { item, error in
            print("XXX 3: contentType[\(contentType)], item[\(item as Optional)], error[\(error as Optional)]")
            if let nsurl = item as? NSURL {
              print("XXX 4: nsurl[\(nsurl)]")
              // swiftUIView.text = nsurl.absoluteString ?? "null"
              if let nsurlString = nsurl.absoluteString {
                print("XXX 5: nsurlString[\(nsurlString)]")
                if let url = URL(string: nsurlString) {
                  print("XXX 5: url[\(url)]")
                  DispatchQueue.main.async {
                    self.showSwiftUIView(url)
                  }
                }
              }
            }
          })
        }
      }
    }

  }

  func showSwiftUIView(_ url: URL) {

    // Create model + fetch (async)
    let shareModel = ShareModel()
    shareModel.fetch(url: url) { corePin in

      // Create view (after async fetch)
      let swiftUIView = ShareView(
        cloudKitSyncMonitor: shareModel.cloudKitSyncMonitor,
        corePin: corePin
      )
      let hc = UIHostingController(rootView: swiftUIView)
      self.addChild(hc)
      self.view.addSubview(hc.view)
      hc.didMove(toParent: self)
      hc.view.backgroundColor = UIColor.white
      hc.view.translatesAutoresizingMaskIntoConstraints = false
      hc.view.heightAnchor  .constraint(equalTo: self.view.heightAnchor)  .isActive = true
      hc.view.leftAnchor    .constraint(equalTo: self.view.leftAnchor)    .isActive = true
      hc.view.rightAnchor   .constraint(equalTo: self.view.rightAnchor)   .isActive = true
      hc.view.centerYAnchor .constraint(equalTo: self.view.centerYAnchor) .isActive = true

    }
  }

}
