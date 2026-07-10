import SwiftUI

@main
struct CursorIMEApp: App {
    // NOTE: The overlay badge and the menu bar item are both driven from
    // AppDelegate; the adaptor keeps it alive. No window is needed.
    // swiftlint:disable unused_declaration
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // swiftlint:enable unused_declaration

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
