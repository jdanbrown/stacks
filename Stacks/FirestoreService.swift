import Firebase
import FirebaseFirestore
import Logging
import SwiftUI

class FirestoreService: ObservableObject {

  let log = Logger(label: "Stacks.FirestoreService")

  @ObservedObject var auth: AuthService

  // NOTE No Pins stuff in here (like firestore.dart), put all that in PinsModel

  // Very large cache size by default
  //  - Built-in default is a measly 40mb
  //  - https://firebase.google.com/docs/firestore/manage-data/enable-offline#configure_cache_size
  let cacheSizeBytes: Int = 1 * Int(pow(Double(1024), Double(3))) // 1gb

  init(auth: AuthService) {
    self.auth = auth
  }

  var db: Firestore {
    let db = Firestore.firestore()
    db.settings = FirestoreSettings()
    db.settings.cacheSizeBytes = Int64(cacheSizeBytes)
    return db
  }

  var user: User {
    get { return auth.user! }
  }

}
