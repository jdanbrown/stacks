# Docs

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

## Project
- https://paper.dropbox.com/doc/A-Pinboard-App--BXJKXToyBC9Vp46eYJRpvBhGAg-PJzwB3vc6xc0UpxsYn8rb
- https://pinboard.in/u:jdanbrown/
- https://console.firebase.google.com/u/0/project/pinbot-9ec7f/firestore/

## Setup firebase/swift
- https://firebase.google.com/docs/ios/installation-methods
- https://github.com/firebase/firebase-ios-sdk/blob/master/SwiftPackageManager.md

## Swift/firebase examples
- https://github.com/Sullivan677/To-Doswiftui
- https://designcode.io/swiftui-advanced-handbook-firebase-auth
- https://www.raywenderlich.com/11609977-getting-started-with-cloud-firestore-and-swiftui#toc-anchor-016
- https://medium.com/swift-productions/swiftui-easy-to-do-list-with-firebase-2637c878cf1a

## SwiftUI docs
- https://developer.apple.com/documentation/swiftui
- https://developer.apple.com/documentation/swiftui/state-and-data-flow
- https://developer.apple.com/documentation/swiftui/managing-user-interface-state
- https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
- https://developer.apple.com/documentation/uikit/view_controllers/restoring_your_app_s_state_with_swiftui
- https://developer.apple.com/documentation/coredata/loading_and_displaying_a_large_data_feed

## SwiftUI tutorials
- https://developer.apple.com/tutorials/SwiftUI
- https://developer.apple.com/documentation/swiftui/fruta_building_a_feature-rich_app_with_swiftui
- https://developer.apple.com/tutorials/swiftui/working-with-ui-controls

## SwiftUI books
- https://www.objc.io/books/thinking-in-swiftui/

# Troubleshooting
- 100% cpu from Simulator/Spotlight when rendering Previews / running Simulator
  - https://developer.apple.com/forums/thread/682253
  - Bug in Xcode 13.1, claims to be fixed in 13.2 beta
- `No such module 'Firebase'` when showing Previews / when building target StacksUITests
  - Targets Stacks and StacksTests built fine, but StacksUITests failed with that error
  - I didn't find a solution with ~1 page of googling
  - Hacky workaround: I simply deleted the StacksUITests target, because I'll ~never use it
