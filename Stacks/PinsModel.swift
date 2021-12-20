import Combine
import Firebase
import FirebaseFirestore
import GoogleSignIn
import SwiftUI
import XCGLogger

class PinsModel: ObservableObject {

  var auth: AuthService
  var firestore: FirestoreService

  @Published var pins = Obs([Pin]())

  private var listeners: [ListenerRegistration] = []
  private var cancellables: [Cancellable] = [] // NOTE Must retain all .sink return values else they get deinit-ed and silently .cancel-ed!

  init(auth: AuthService, firestore: FirestoreService) {
    self.auth = auth
    self.firestore = firestore
    cancellables += [
      self.auth.userDidChange_.sink { (oldUser, newUser) in self.onUserChange(oldUser: oldUser, newUser: newUser) },
    ]
  }

  func onUserChange(oldUser: User?, newUser: User?) {
    log.info("oldUser[\(opt: oldUser)] -> newUser[\(opt: newUser)]")
    unlistenToAll()
    if let user = newUser {
      listenToPins(user: user)
    }
  }

  func unlistenToAll() {
    log.info("listeners[\(listeners.count)]")
    for listener in listeners {
      listener.remove()
    }
    listeners = []
  }

  func pinsCollection(user: User) -> CollectionReference {
    return firestore.db.collection("/users/\(user.uid)/pins")
  }

  // https://firebase.google.com/docs/firestore/query-data/listen
  // https://firebase.google.com/docs/firestore/query-data/listen#listen_to_multiple_documents_in_a_collection
  func listenToPins(user: User) {
    let c = pinsCollection(user: user)
    log.info("Listening to collection[\(c)]")
    listeners.append(
      c.addSnapshotListener { querySnapshot, error in
        guard let documents = querySnapshot?.documents else {
          log.error("Error in snapshot: \(opt: error)")
          return
        }
        log.info("Got snapshot: documents[\(documents.count)]")
        self.pins.value = documents.map { queryDocumentSnapshot -> Pin in
          return Pin.parseMap(
            ref: queryDocumentSnapshot.reference,
            map: queryDocumentSnapshot.data()
          )
        }
      }
    )
  }

  // TODO Add pins stuff from firestore.dart
  //  - pinFromUrl
  //  - pinFromId
  //  - pinFromDoc
  //  - insertPinsIfNotExists
  //  - upsertPins
  //  - deletePin
  //  - togglePinIsRead

}
