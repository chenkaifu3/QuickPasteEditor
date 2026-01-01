import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static var shared: AppDelegate?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private(set) weak var mainWindow: NSWindow?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerHotKey()
        DispatchQueue.main.async { [weak self] in
            self?.mainWindow = NSApplication.shared.windows.first
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotKey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func setMainWindowIfNeeded(_ window: NSWindow?) {
        if mainWindow == nil {
            mainWindow = window
            mainWindow?.delegate = self
            mainWindow?.isReleasedWhenClosed = false
        }
    }

    private func registerHotKey() {
        let keyCode: UInt32 = UInt32(kVK_ANSI_V)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let hotKeyID = EventHotKeyID(signature: 0x51504548, id: 1) // "QPEH"
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr, hotKeyID.signature == 0x51504548, hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    AppDelegate.shared?.showMainWindow()
                }
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventSpec, nil, &eventHandlerRef)
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func showMainWindow() {
        let app = NSApplication.shared
        app.activate(ignoringOtherApps: true)
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
        } else if let firstWindow = app.windows.first {
            mainWindow = firstWindow
            mainWindow?.delegate = self
            mainWindow?.isReleasedWhenClosed = false
            firstWindow.makeKeyAndOrderFront(nil)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
