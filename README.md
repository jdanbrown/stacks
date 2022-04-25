# Stacks
- https://paper.dropbox.com/doc/A-Pinboard-App--BXJKXToyBC9Vp46eYJRpvBhGAg-PJzwB3vc6xc0UpxsYn8rb
- https://pinboard.in/u:jdanbrown/
- https://console.firebase.google.com/u/0/project/pinbot-9ec7f/firestore/

# Docs

## Login to firebase — this will store creds for fastlane to use
- https://firebase.google.com/docs/cli#sign-in-test-cli
```sh
firebase login
firebase projects:list # To verify
firebase login --reauth # If things aren't working, use this to force re-login
```

## Distribute to firebase using fastlane
- https://firebase.google.com/docs/app-distribution/ios/distribute-fastlane
- https://console.firebase.google.com/u/0/project/pinbot-9ec7f/appdistribution/app/ios:org.jdanbrown.Stacks/releases
```sh
bin/fastlane firebase_distribute_beta
```

## TODO Github actions -- to move fastlane(xcodebuild,firebase) off my laptop
- Goal
  - Use cloud instead of 10m+ of laptop battery to distribute builds to Firebase/TestFlight
- Read the docs first
  - https://docs.github.com/en/actions
  - https://docs.github.com/en/actions/quickstart
  - https://docs.github.com/en/actions/learn-github-actions
  - https://docs.github.com/en/actions/managing-workflow-runs
  - https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift
  - https://docs.github.com/en/actions/deployment/deploying-xcode-applications
  - https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows
  - https://docs.github.com/en/actions/using-github-hosted-runners
  - https://docs.github.com/en/actions/security-guides
- Resources
  - https://github.com/nektos/act -- run github workflows locally (for testing, and replace bin?)
- Approaches
  1. Does our existing Fastfile just work in the cloud?
    - https://github.com/marketplace/actions/fastlane-action
  2. Port Fastfile to github actions, and replace local fastlane with act
    - https://github.com/mxcl/xcodebuild
    - https://github.com/marketplace/actions/firebase-app-distribution
    - https://github.com/marketplace/actions/github-action-for-firebase

## Manage firebase
- Project files
  - https://firebase.google.com/docs/cli -- install cli
  - `firebase init` -- setup project files (maybe can run again to add more types of project files?)
  - `firebase deploy` -- deploy changes from project files (e.g. firestore.rules, firestore.indexes.json)
  - `firebase deploy --only firestore:rules` -- deploy only changes to firestore rules
- Web console
  - https://console.firebase.google.com/u/0/project/pinbot-9ec7f
  - https://console.firebase.google.com/u/0/project/pinbot-9ec7f/firestore
  - https://console.firebase.google.com/u/0/project/pinbot-9ec7f/firestore/rules

## Xcode: Swift Package Manager
- https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app
  - Project: Stacks -> Targets: Stacks -> General -> Frameworks, Libraries

## Xcode: SwiftUI Previews
- https://www.wwdcnotes.com/notes/wwdc20/10149/ — Structure your app for SwiftUI previews
- https://www.avanderlee.com/swiftui/previews-different-states/
- https://www.swiftbysundell.com/articles/getting-the-most-out-of-xcode-previews/
- https://swiftwithmajid.com/2021/03/10/mastering-swiftui-previews/
- https://useyourloaf.com/blog/swiftui-preview-data/
- https://www.avanderlee.com/xcode/development-assets-preview-catalog/

## Xcode: Create icon sets
- Use app: Icon Set Creator
  - https://stackoverflow.com/a/45122603/397334

## Swift: What's up with async/await vs. Future/Combine?
- Are there no happy paths to interface them?
  - https://forums.swift.org/t/how-to-mix-async-await-and-combine/49394/4
- Is Combine going away?
  - https://benscheirman.com/2021/06/async-await-and-the-future-of-combine/
  - https://wwdcbysundell.com/2021/the-future-of-combine/
  - https://developer.apple.com/documentation/swift/asyncsequence

## Swift/Firebase: Setup
- https://firebase.google.com/docs/ios/installation-methods
- https://github.com/firebase/firebase-ios-sdk/blob/master/SwiftPackageManager.md

## Swift/Firebase: Extensions
- https://github.com/firebase/firebase-ios-sdk/tree/master/Firestore/Swift
  - `import FirebaseFirestoreSwift`
- https://github.com/firebase/firebase-ios-sdk/tree/master/FirebaseCombineSwift
  - `import FirebaseAuthCombineSwift`
  - `import FirebaseFirestoreCombineSwift`
  - `import FirebaseFunctionsCombineSwift`
  - `import FirebaseStorageCombineSwift`

## Swift/Firebase: Examples
- https://github.com/Sullivan677/To-Doswiftui
- https://designcode.io/swiftui-advanced-handbook-firebase-auth
- https://www.raywenderlich.com/11609977-getting-started-with-cloud-firestore-and-swiftui#toc-anchor-016
- https://medium.com/swift-productions/swiftui-easy-to-do-list-with-firebase-2637c878cf1a

## Swift/Firebase: Articles
- How to map firestore `.data()` using `Codable`
  - https://peterfriese.dev/firestore-codable-the-comprehensive-guide/

## SwiftUI: Overviews / Entrypoints
- https://developer.apple.com/design/human-interface-guidelines/ios
- https://www.objc.io/books/thinking-in-swiftui
- https://www.hackingwithswift.com/quick-start/swiftui
- https://swiftontap.com/
- https://useyourloaf.com/
- https://fuckingswiftui.com/

## SwiftUI: Docs
- https://developer.apple.com/documentation/swiftui
- https://developer.apple.com/documentation/swiftui/state-and-data-flow
- https://developer.apple.com/documentation/swiftui/managing-user-interface-state
- https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
- https://developer.apple.com/documentation/uikit/view_controllers/restoring_your_app_s_state_with_swiftui
- https://developer.apple.com/documentation/coredata/loading_and_displaying_a_large_data_feed

## SwiftUI: Design
- https://developer.apple.com/design/human-interface-guidelines/ios/views
- https://developer.apple.com/design/human-interface-guidelines/ios/controls
- https://developer.apple.com/design/human-interface-guidelines/ios/bars
- https://developer.apple.com/design/human-interface-guidelines/ios/user-interaction/gestures
- https://developer.apple.com/design/human-interface-guidelines/ios/app-architecture/navigation
- https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color
- https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/materials
- https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
- https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout

## SwiftUI: Colors
- https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/
- https://developer.apple.com/documentation/uikit/uicolor/standard_colors

## SwiftUI: Symbols
- https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/system-icons
- https://www.avanderlee.com/swift/sf-symbols-guide
  - Very helpful!
- https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview
- https://developer.apple.com/sf-symbols

## SwiftUI: Navigation
- https://www.hackingwithswift.com/articles/216/complete-guide-to-navigationview-in-swiftui
- https://sarunw.com/posts/navigation-in-swiftui/
- https://www.ralfebert.com/ios/swiftui-programmatic-navigationview/
  - Tip: `.navigationViewStyle(.stack)` -- else you can't stack navigations
  - Tip: Two libraries for more flexible + programmatic navigation
    - https://github.com/matteopuc/swiftui-navigation-stack
    - https://github.com/Bahn-X/swift-composable-navigator

## SwiftUI: Gestures
- https://developer.apple.com/documentation/swiftui/gestures
  - https://developer.apple.com/documentation/swiftui/adding-interactivity-with-gestures
  - https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures
- https://developer.apple.com/documentation/swiftui/gesture
  - https://developer.apple.com/documentation/swiftui/longpressgesture
- https://www.hackingwithswift.com/books/ios-swiftui/how-to-use-gestures-in-swiftui
- Stackoverflow tips
  - https://stackoverflow.com/questions/58284994/swiftui-how-to-handle-both-tap-long-press-of-button

## SwiftUI: Flex / wrap
- FlexView
  - https://github.com/berbschloe/FlexView (1 star)
    - Based on helpful article: https://www.fivestars.blog/articles/flexible-swiftui
    - Claims that LazyVGrid/LazyHGrid can't do wrap (corroborates my takeaway from docs and experimenting)
  - Comparison (e259dce)
    - Speed: 4/5 -- very close to pure Text() version
    - Preview sizing: too much vertical padding, sometimes correct (I _think_ I observed it be correct once?)
  - Went with this one!
    - Vendored it so I could make edits (MIT license)
- WrappingStack
  - https://github.com/diniska/swiftui-wrapping-stack (17 stars)
  - Comparison (e259dce)
    - Speed: 3.5/5 -- feels only very slightly slower than FlexView
    - Preview sizing: too much vertical padding
- WrappingHStack
  - https://github.com/dkk/WrappingHStack (55 stars)
  - Works, but slow-ish
  - Comparison (e259dce)
    - Speed: 1/5 -- way slower than pure Text() version, and feels annoyingly slow overall
    - Preview sizing (PinView): bad, vertical clipping
- WrapStack
  - https://github.com/swiftuilib/wrap-stack (22 stars)
  - Error: "The compiler is unable to type-check this expression in reasonable time"
    - https://github.com/swiftuilib/wrap-stack/issues/3
      - 2021-09-14 created
      - 2022-01-22 still open
- FlexLayout
  - https://github.com/layoutBox/FlexLayout (1.5k stars)
  - Flexbox in swift
  - Supports wrap: https://github.com/layoutBox/FlexLayout#wrap
  - No swiftui support :(

## SwiftUI: Grids / flexbox / wrap
- https://swiftui-lab.com/impossible-grids/
  - Very illustrative!
  - `LazyHGrid`, `LazyVGrid`, `GridItem`
- https://github.com/exyte/Grid
  - Mature, flexible

## SwiftUI libs
- More widgets
  - https://github.com/SwiftUIX/SwiftUIX
  - https://github.com/AvdLee/SwiftUIKitView
- Markdown
  - https://github.com/gonzalezreal/MarkdownUI — using this one, simple to use
  - https://github.com/johnxnguyen/Down – looks slightly more complex to use, haven't tried yet
- Plotting
  - https://github.com/AppPear/ChartView
  - https://github.com/mecid/SwiftUICharts
  - https://github.com/spacenation/swiftui-charts

## SwiftUI: Helpful articles
- `@State` vs. `@Binding` vs. `@StateObject` vs. `@ObservedObject` vs. `@EnvironmentObject`
  - Summary
    - Value types
      - `@State` for owner
      - `@Binding` for children
    - Object types
      - `@StateObject` for owner
      - `@ObservedObject` for children
      - `@EnvironmentObject` as a bonus thing -- no analogue for value types
  - Articles
    - https://www.hackingwithswift.com/quick-start/swiftui/whats-the-difference-between-observedobject-state-and-environmentobject
    - Book ch2: https://www.objc.io/books/thinking-in-swiftui/
  - Docs
    - https://developer.apple.com/documentation/swiftui/state-and-data-flow
    - https://developer.apple.com/documentation/swiftui/managing-user-interface-state
    - https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
  - Reference
    - https://developer.apple.com/documentation/swiftui/state
    - https://developer.apple.com/documentation/swiftui/binding
    - https://developer.apple.com/documentation/swiftui/stateobject
    - https://developer.apple.com/documentation/swiftui/observedobject
    - https://developer.apple.com/documentation/swiftui/environmentobject

# Troubleshooting
- 100% cpu from Simulator/Spotlight when rendering Previews / running Simulator
  - https://developer.apple.com/forums/thread/682253
  - Bug in Xcode 13.1, claims to be fixed in 13.2 beta
- `No such module 'Firebase'` when showing Previews / when building target StacksUITests
  - Targets Stacks and StacksTests built fine, but StacksUITests failed with that error
  - I didn't find a solution with ~1 page of googling
  - Hacky workaround: I simply deleted the StacksUITests target, because I'll ~never use it
- Adding new device to firebase app distribution gets stuck at `Waiting for developer`
  - Problem: Local Xcode provisioning profile is out of date
    - So even though the new device UUID was added to https://developer.apple.com/account/resources/devices/list,
      rebuilding the app doesn't include it because the local profile doesn't include the new device
  - Solution: Delete the local provisioning profile file and trigger Xcode to re-download the new one
    - Open `~/Library/MobileDevice/Provisioning Profiles/` in Finder
    - Switch to "as Columns" view (cmd-3)
    - Down-arrow through each file until one says "iOS Team Provisioning Profile: *"
    - Delete it
    - Go Xcode -> Runner project -> Targets: Runner -> Signing & Capabilities -> Provisioning Profile
    - It will automatically re-download the new profile upon viewing (or maybe you have to click something)
  - https://github.com/firebase/firebase-ios-sdk/issues/6223
- WKWebView won't load `http:` urls
  - Solution: Info.plist -> `NSAppTransportSecurity` -> `NSAllowsArbitraryLoadsInWebContent`
  - https://www.hackingwithswift.com/example-code/wkwebview/how-to-load-http-content-in-wkwebview-and-uiwebview
- `There is no XCFramework found at` when building in Xcode or fastlane
  - https://github.com/fastlane/fastlane/issues/19783
  - Maybe a bug in fastlane ~1.999/1.201?
  - Workaround: Quit xcode when running fastlane build
