import AppKit
import Carbon
import ServiceManagement

enum Defaults {
    static let showMenuBarIcon = "showMenuBarIcon"
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let badgeSize = NSSize(width: 34, height: 34)
    /// Offset from the cursor hotspot: the badge sits to the lower-right of the pointer.
    private let offset = NSPoint(x: 16, y: -40)

    private var panel: NSPanel!
    private var badge: BadgeView!
    private var statusItem: NSStatusItem!
    private var launchAtLoginItem: NSMenuItem!
    private var lastState: IMEState?
    private var lastMouse = NSPoint(x: -1, y: -1)
    private var frame = 0
    private var timer: Timer?
    private var imeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_: Notification) {
        setupBadge()
        setupStatusItem()
        startIMEObserver()
        startTimer()
        updateState()
    }

    /// Relaunching the app from Finder while it is already running restores a
    /// hidden menu bar icon.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        setStatusItemVisible(true)
        return true
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let icon = NSImage(named: "MenuBarIcon")
        icon?.isTemplate = true
        icon?.accessibilityDescription = "CursorIME"
        statusItem.button?.image = icon

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(
            withTitle: "About CursorIME",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        menu.addItem(launchAtLoginItem)
        menu.addItem(
            withTitle: "Hide Menu Bar Icon",
            action: #selector(hideStatusItem),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit CursorIME",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem.menu = menu
        updateLaunchAtLoginItem()

        // Honor the stored preference on launch (visible by default).
        let visible = UserDefaults.standard.object(forKey: Defaults.showMenuBarIcon) as? Bool ?? true
        statusItem.isVisible = visible
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("CursorIME: failed to toggle launch at login: \(error)")
        }
        updateLaunchAtLoginItem()
    }

    private func updateLaunchAtLoginItem() {
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func hideStatusItem() {
        setStatusItemVisible(false)
    }

    private func setStatusItemVisible(_ visible: Bool) {
        statusItem.isVisible = visible
        UserDefaults.standard.set(visible, forKey: Defaults.showMenuBarIcon)
    }

    private func setupBadge() {
        badge = BadgeView(frame: NSRect(origin: .zero, size: badgeSize))

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: badgeSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = badge
    }

    /// Instant IME updates from input-source-change notifications. The observer
    /// fires on the main queue, so we can safely assume main-actor isolation.
    private func startIMEObserver() {
        let name = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        imeObserver = DistributedNotificationCenter.default().addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateState()
            }
        }
    }

    /// A single 60fps timer caps how often we move the window, regardless of how
    /// fast the mouse reports events. It runs on the main run loop.
    private func startTimer() {
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        // Safety net for IMEs that do not post the change notification on every
        // kana/eisu toggle: re-check roughly twice a second.
        frame += 1
        if frame % 30 == 0 {
            updateState()
        }

        // Nothing to move while the badge is hidden (i.e. not Japanese input),
        // so English typing with the mouse moving costs nothing here.
        guard lastState == .japanese else { return }

        let location = NSEvent.mouseLocation
        if location != lastMouse {
            lastMouse = location
            panel.setFrameOrigin(NSPoint(x: location.x + offset.x, y: location.y + offset.y))
        }
    }

    /// Show the badge only while Japanese input is active; hide it otherwise.
    private func updateState() {
        let state = currentIMEState()

        guard state != lastState else { return }
        lastState = state

        if state == .japanese {
            lastMouse = NSPoint(x: -1, y: -1) // force a reposition on the next tick
            let location = NSEvent.mouseLocation
            panel.setFrameOrigin(NSPoint(x: location.x + offset.x, y: location.y + offset.y))
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    /// Refresh the checkbox in case the login item was changed elsewhere.
    func menuNeedsUpdate(_: NSMenu) {
        updateLaunchAtLoginItem()
    }
}
