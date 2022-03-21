import SwiftUI

// Programmatic navigation (for any View)
//  - Conceptually this is just one @State, but we have to do State/State/Binding to render the NavigationLink in two
//    phases, which we need so that the enter animation doesn't get skipped
//    - Phase 1: render an unselected NavigationLink
//    - Phase 2: onAppear, select the rendered NavigationLink
//  - The Binding is to give us 3 states instead of 4: when NavigationLink resets _tagSelectionPhaseTwo = false, also
//    reset _push = nil, else our two-phase rendering logic breaks down

class AutoNavigationLinkModel: ObservableObject {

  @Published var _push: AnyView? = nil
  @Published var _pushPhaseTwo: Bool = false

  var pushPhaseTwo: Binding<Bool> {
    return Binding(
      get: { self._pushPhaseTwo },
      set: { x in
        self._pushPhaseTwo = x
        if x == false {
          self._push = nil
        }
      }
    )
  }

  func push<X: View>(_ view: X) {
    _push = AnyView(view)
  }

}

struct AutoNavigationLink: View {

  let model: AutoNavigationLinkModel

  var body: some View {
    if let _push = model._push {
      // Phase 1: Render an unselected NavigationLink
      NavigationLink(
        destination: _push,
        isActive: model.pushPhaseTwo
      ) { EmptyView() }
        .hidden()
        .onAppear {
          // Phase 2: Immediately select it
          self.model._pushPhaseTwo = true
        }
    }
  }

}
