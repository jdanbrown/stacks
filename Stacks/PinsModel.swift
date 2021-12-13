import FirebaseFirestore
import Logging
import SwiftUI

class PinsModel: ObservableObject {

  let log = Logger(label: "Stacks.PinsModel")

  @ObservedObject var firestore: FirestoreService

  @Published var pins = [Pin]()

  init(firestore: FirestoreService) {
    self.firestore = firestore
    listenToPins()
  }

  var pinsCollection: CollectionReference {
    return firestore.db.collection("/users/\(firestore.user.uid)/pins")
  }

  // https://firebase.google.com/docs/firestore/query-data/listen
  // https://firebase.google.com/docs/firestore/query-data/listen#listen_to_multiple_documents_in_a_collection
  func listenToPins() {
    pinsCollection.addSnapshotListener { querySnapshot, error in
      guard let documents = querySnapshot?.documents else {
        print("ERROR: fetchPins failed to fetch: \(error!)")
        return
      }
      self.pins = documents.map { (queryDocumentSnapshot) -> Pin in
        let map = queryDocumentSnapshot.data()
        return Pin.parseMap(map: map)
      }
    }
  }

  // TODO Pins stuff from firestore.dart
  //  - pinFromUrl
  //  - pinFromId
  //  - pinFromDoc
  //  - insertPinsIfNotExists
  //  - upsertPins
  //  - deletePin
  //  - togglePinIsRead

}
