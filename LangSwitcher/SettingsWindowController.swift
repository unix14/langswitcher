import Cocoa
import ServiceManagement

class HorizontalGradientView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let colors = [
            NSColor(red: 0.07, green: 0.07, blue: 0.22, alpha: 1.0).cgColor,
            NSColor(red: 0.20, green: 0.05, blue: 0.38, alpha: 1.0).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) else { return }
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: bounds.width, y: 0), options: [])
    }
}

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    
    private var isRecording = false
    private var eventMonitor: Any?
    
    private var bannerView: HorizontalGradientView!
    private var iconView: NSImageView!
    private var titleLabel: NSTextField!
    private var bylineLabel: NSTextField!
    
    private var loginCheckbox: NSButton!
    private var hotkeyButton: NSButton!
    private var shortcutLabel: NSTextField!
    
    private var accessStatusLabel: NSTextField!
    private var accessButton: NSButton!
    
    private var languagesLabel: NSTextField!
    private var aboutLabel: NSTextField!
    private var footerLabel: NSTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 420, height: 540),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LangSwitcher Settings"
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        window.delegate = self
        setupUI()
    }
    
    func show() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        refreshAll()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(red: 0.07, green: 0.06, blue: 0.13, alpha: 1.0).cgColor
        
        // 1. Banner
        bannerView = HorizontalGradientView(frame: CGRect(x: 0, y: 444, width: 420, height: 96))
        contentView.addSubview(bannerView)
        
        iconView = NSImageView(frame: CGRect(x: 20, y: 460, width: 60, height: 60))
        iconView.image = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        contentView.addSubview(iconView)
        
        titleLabel = NSTextField(frame: CGRect(x: 94, y: 486, width: 300, height: 24))
        titleLabel.stringValue = "LangSwitcher"
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        contentView.addSubview(titleLabel)
        
        bylineLabel = NSTextField(frame: CGRect(x: 95, y: 464, width: 300, height: 18))
        bylineLabel.stringValue = "by Eyal Yaakobi  ·  v1.4"
        bylineLabel.font = NSFont.systemFont(ofSize: 12)
        bylineLabel.textColor = NSColor.white.withAlphaComponent(0.65)
        bylineLabel.isBezeled = false
        bylineLabel.drawsBackground = false
        bylineLabel.isEditable = false
        bylineLabel.isSelectable = false
        contentView.addSubview(bylineLabel)
        
        // 2. GENERAL
        contentView.addSubview(createSectionHeader(title: "GENERAL", y: 415))
        
        loginCheckbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleLogin))
        let pStyle = NSMutableParagraphStyle()
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 13),
            .paragraphStyle: pStyle
        ]
        loginCheckbox.attributedTitle = NSAttributedString(string: "Launch at Login", attributes: attrs)
        loginCheckbox.frame = CGRect(x: 24, y: 385, width: 372, height: 22)
        contentView.addSubview(loginCheckbox)
        
        contentView.addSubview(createSeparator(y: 370))
        
        // 3. KEYBOARD SHORTCUT
        contentView.addSubview(createSectionHeader(title: "KEYBOARD SHORTCUT", y: 345))
        
        hotkeyButton = NSButton(frame: CGRect(x: 24, y: 310, width: 96, height: 28))
        hotkeyButton.bezelStyle = .rounded
        hotkeyButton.target = self
        hotkeyButton.action = #selector(hotkeyButtonClicked)
        contentView.addSubview(hotkeyButton)
        
        shortcutLabel = NSTextField(frame: CGRect(x: 130, y: 315, width: 266, height: 18))
        shortcutLabel.stringValue = "Click to record a new shortcut"
        shortcutLabel.font = NSFont.systemFont(ofSize: 12)
        shortcutLabel.textColor = NSColor(white: 1.0, alpha: 0.60)
        shortcutLabel.isBezeled = false
        shortcutLabel.drawsBackground = false
        shortcutLabel.isEditable = false
        shortcutLabel.isSelectable = false
        contentView.addSubview(shortcutLabel)
        
        contentView.addSubview(createSeparator(y: 295))
        
        // 4. ACCESSIBILITY
        contentView.addSubview(createSectionHeader(title: "ACCESSIBILITY", y: 270))
        
        accessStatusLabel = NSTextField(frame: CGRect(x: 24, y: 240, width: 372, height: 18))
        accessStatusLabel.isBezeled = false
        accessStatusLabel.drawsBackground = false
        accessStatusLabel.isEditable = false
        accessStatusLabel.isSelectable = false
        contentView.addSubview(accessStatusLabel)
        
        accessButton = NSButton(frame: CGRect(x: 24, y: 205, width: 156, height: 28))
        accessButton.bezelStyle = .rounded
        accessButton.target = self
        accessButton.action = #selector(accessButtonClicked)
        contentView.addSubview(accessButton)
        
        contentView.addSubview(createSeparator(y: 190))
        
        // 5. LANGUAGES
        contentView.addSubview(createSectionHeader(title: "LANGUAGES", y: 165))
        
        languagesLabel = NSTextField(frame: CGRect(x: 24, y: 140, width: 372, height: 18))
        languagesLabel.stringValue = "English  ⇄  Hebrew  (automatic detection)"
        languagesLabel.font = NSFont.systemFont(ofSize: 13)
        languagesLabel.textColor = NSColor(white: 1.0, alpha: 0.70)
        languagesLabel.isBezeled = false
        languagesLabel.drawsBackground = false
        languagesLabel.isEditable = false
        languagesLabel.isSelectable = false
        contentView.addSubview(languagesLabel)
        
        contentView.addSubview(createSeparator(y: 125))
        
        // 6. ABOUT
        aboutLabel = NSTextField(frame: CGRect(x: 24, y: 75, width: 372, height: 36))
        aboutLabel.stringValue = "LangSwitcher converts text typed in the wrong keyboard layout.\nPress the hotkey and it fixes the selection automatically."
        aboutLabel.font = NSFont.systemFont(ofSize: 12)
        aboutLabel.textColor = NSColor(white: 1.0, alpha: 0.70)
        aboutLabel.isBezeled = false
        aboutLabel.drawsBackground = false
        aboutLabel.isEditable = false
        aboutLabel.isSelectable = false
        contentView.addSubview(aboutLabel)
        
        contentView.addSubview(createSeparator(y: 50))
        
        // 7. Footer
        footerLabel = NSTextField(frame: CGRect(x: 0, y: 20, width: 420, height: 15))
        footerLabel.stringValue = "© 2026 Eyal Yaakobi · LangSwitcher v1.4"
        footerLabel.font = NSFont.systemFont(ofSize: 11)
        footerLabel.textColor = NSColor(white: 1.0, alpha: 0.40)
        footerLabel.alignment = .center
        footerLabel.isBezeled = false
        footerLabel.drawsBackground = false
        footerLabel.isEditable = false
        footerLabel.isSelectable = false
        contentView.addSubview(footerLabel)
    }
    
    private func createSectionHeader(title: String, y: CGFloat) -> NSTextField {
        let header = NSTextField(frame: CGRect(x: 24, y: y, width: 372, height: 14))
        header.stringValue = title.uppercased()
        header.font = NSFont.boldSystemFont(ofSize: 10)
        header.textColor = NSColor(white: 1.0, alpha: 0.50)
        header.isBezeled = false
        header.drawsBackground = false
        header.isEditable = false
        header.isSelectable = false
        return header
    }
    
    private func createSeparator(y: CGFloat) -> NSBox {
        let separator = NSBox(frame: CGRect(x: 0, y: y, width: 420, height: 1))
        separator.boxType = .custom
        separator.borderType = .noBorder
        separator.fillColor = NSColor(white: 1.0, alpha: 0.12)
        return separator
    }
    
    func refreshAll() {
        refreshLoginCheckbox()
        refreshHotkeyButton()
        refreshAccessibility()
    }
    
    private func refreshLoginCheckbox() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        loginCheckbox.state = isEnabled ? .on : .off
    }
    
    private func refreshHotkeyButton() {
        let title = HotkeyStore.shared.displayString
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: isRecording ? NSColor.systemOrange : NSColor.white,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .paragraphStyle: paragraph
        ]
        hotkeyButton.attributedTitle = NSAttributedString(string: title, attributes: attrs)
    }
    
    private func refreshAccessibility() {
        let isTrusted = AXIsProcessTrusted()
        let buttonTitle = isTrusted ? "Open System Settings" : "Grant Access"
        
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 13),
            .paragraphStyle: pStyle
        ]
        accessButton.attributedTitle = NSAttributedString(string: buttonTitle, attributes: attrs)
        
        if isTrusted {
            accessStatusLabel.stringValue = "✓ Granted"
            accessStatusLabel.textColor = NSColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0)
            accessStatusLabel.font = NSFont.boldSystemFont(ofSize: 13)
        } else {
            accessStatusLabel.stringValue = "✗ Not granted"
            accessStatusLabel.textColor = NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
            accessStatusLabel.font = NSFont.boldSystemFont(ofSize: 13)
        }
    }
    
    @objc private func toggleLogin() {
        let shouldEnable = loginCheckbox.state == .on
        do {
            if shouldEnable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to change login service status: \(error)")
            refreshLoginCheckbox()
        }
    }
    
    @objc private func hotkeyButtonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.systemOrange,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .paragraphStyle: paragraph
        ]
        hotkeyButton.attributedTitle = NSAttributedString(string: "Press key…", attributes: attrs)
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            let keyCode = event.keyCode
            if keyCode == 53 { // Escape cancels
                self.stopRecording()
                return nil
            }
            
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            if !flags.isEmpty {
                HotkeyStore.shared.save(keyCode: keyCode, modifiers: flags)
                self.stopRecording()
                return nil
            }
            
            return event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        refreshHotkeyButton()
    }
    
    @objc private func accessButtonClicked() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        refreshAccessibility()
    }
    
    func windowWillClose(_ notification: Notification) {
        if isRecording {
            stopRecording()
        }
    }
}
