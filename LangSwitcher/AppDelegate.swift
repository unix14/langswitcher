import Cocoa
import Carbon

func carbonHotkeyProc(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let userData = userData else { return noErr }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        delegate.handleHotkey()
    }
    return noErr
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var carbonHandlerRef: EventHandlerRef?
    private var carbonHotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        installCarbonHandler()
        registerHotkey()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyChanged),
            name: .hotkeyStoreChanged,
            object: nil
        )
        
        SplashWindowController.show()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if !AXIsProcessTrusted() {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
            }
        }
        
        let launchCountKey = "launchCount"
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(launchCount + 1, forKey: launchCountKey)
        
        if launchCount < 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                SettingsWindowController.shared.show()
            }
        }
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        statusItem.behavior = []
        
        if let button = statusItem.button {
            let title = "A⇄א"
            let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraph
            ]
            button.attributedTitle = NSAttributedString(string: title, attributes: attrs)
            button.toolTip = "LangSwitcher"
        }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit LangSwitcher", action: nil, keyEquivalent: "q")
        quitItem.target = NSApp
        quitItem.action = #selector(NSApplication.terminate(_:))
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }
    
    func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyProc,
            1,
            &eventType,
            selfPtr,
            &carbonHandlerRef
        )
        if status != noErr {
            print("Error installing Carbon event handler: \(status)")
        }
    }
    
    func registerHotkey() {
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            carbonHotKeyRef = nil
        }
        
        let store = HotkeyStore.shared
        let keyCode = UInt32(store.keyCode)
        
        var carbonMods: UInt32 = 0
        let nsMods = store.nsModifiers
        if nsMods.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if nsMods.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if nsMods.contains(.option) { carbonMods |= UInt32(optionKey) }
        if nsMods.contains(.control) { carbonMods |= UInt32(controlKey) }
        
        let hkID = EventHotKeyID(signature: 0x4C535754, id: 1)
        
        let status = RegisterEventHotKey(
            keyCode,
            carbonMods,
            hkID,
            GetApplicationEventTarget(),
            0,
            &carbonHotKeyRef
        )
        if status != noErr {
            print("Error registering Carbon hotkey: \(status)")
        }
    }
    
    @objc func hotkeyChanged() {
        registerHotkey()
    }
    
    func handleHotkey() {
        waitForModifiersReleased { [weak self] in self?.performConversion() }
    }
    
    private func waitForModifiersReleased(_ done: @escaping () -> Void) {
        let held = NSEvent.modifierFlags.intersection([.command, .shift, .option, .control])
        if held.isEmpty { done(); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.waitForModifiersReleased(done)
        }
    }
    
    private func performConversion() {
        let pb = NSPasteboard.general
        let saved = pb.string(forType: .string)
        
        pb.clearContents()
        postKey(keyCode: 8, flags: .maskCommand)  // Cmd+C
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self = self else { return }
            let first = pb.string(forType: .string) ?? ""
            if !first.isEmpty {
                self.applyConversion(text: first, pb: pb, saved: saved)
                return
            }
            // Fallback: nothing selected — try select-all
            self.postKey(keyCode: 0, flags: .maskCommand)  // Cmd+A
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.postKey(keyCode: 8, flags: .maskCommand)  // Cmd+C
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    let second = pb.string(forType: .string) ?? ""
                    if second.isEmpty { self.restore(pb, saved); return }
                    self.applyConversion(text: second, pb: pb, saved: saved)
                }
            }
        }
    }
    
    private func applyConversion(text: String, pb: NSPasteboard, saved: String?) {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let converted = KeyboardLayout.convert(normalized)
        typeText(converted)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.restore(pb, saved)
        }
    }
    
    private func typeText(_ text: String) {
        let src = CGEventSource(stateID: .hidSystemState)
        let units = Array(text.utf16)
        var i = 0
        while i < units.count {
            let end = min(i + 20, units.count)
            let chunk = Array(units[i..<end])
            chunk.withUnsafeBufferPointer { buf in
                guard let event = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true) else { return }
                event.flags = []
                event.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: buf.baseAddress)
                event.post(tap: .cgSessionEventTap)
            }
            i = end
        }
    }
    
    private func postKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let src  = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.flags = flags; up?.flags = flags
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
    
    private func restore(_ pb: NSPasteboard, _ saved: String?) {
        pb.clearContents()
        if let saved = saved {
            pb.setString(saved, forType: .string)
        }
    }
}
