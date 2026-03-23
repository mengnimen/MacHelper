import SwiftUI

@main
struct MacHelperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 520)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 500)  // height 默认高度
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
