import Combine
import SwiftUI
import XCGLogger

class PinsModelMerge: ObservableObject {

  @Published var pins = [Pin]()

  let pinsModelFirestore: PinsModelFirestore
  let pinsModelPinboard: PinsModelPinboard

  private var cancellables: [Cancellable] = [] // NOTE Must retain all .sink return values else they get deinit-ed and silently .cancel-ed!

  init(
    pinsModelFirestore: PinsModelFirestore,
    pinsModelPinboard: PinsModelPinboard
  ) {
    self.pinsModelFirestore = pinsModelFirestore
    self.pinsModelPinboard  = pinsModelPinboard
    self.cancellables += [
      self.pinsModelFirestore .$pins.receive(on: RunLoop.main).sink { pins in self.pins = self.merge(self.pins, pins) },
      self.pinsModelPinboard  .$pins.receive(on: RunLoop.main).sink { pins in self.pins = self.merge(self.pins, pins) },
    ]
  }

  // TODO Store diffs (in CorePinDiff)
  //  - Trim to bound history (n=1000 seems great)
  func merge(_ xs: [Pin], _ ys: [Pin]) -> [Pin] {
    let (zs, diffs) = Pins.merge(xs, ys)
    log.info("diffs[\(diffs.count)]")
    for (i, diff) in diffs.enumerated() {
      print("  diff[\(i)].before")
      for x in diff.before {
        print("    \(x)")
      }
      print("  diff[\(i)].after")
      print("    \(diff.after)")
    }
    return zs
  }

}
