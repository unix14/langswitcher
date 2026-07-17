import Cocoa
import QuartzCore

class SplashWindow: NSWindow {
    override var canBecomeKey: Bool { return false }
    override var canBecomeMain: Bool { return false }
}

class SplashView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 22
        layer?.masksToBounds = true
        
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            NSColor(red: 0.07, green: 0.07, blue: 0.22, alpha: 1.0).cgColor,
            NSColor(red: 0.22, green: 0.05, blue: 0.42, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.0)
        layer?.addSublayer(gradient)
        
        let highlight = CALayer()
        highlight.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
        highlight.backgroundColor = NSColor(white: 1.0, alpha: 0.12).cgColor
        layer?.addSublayer(highlight)
        
        let iconImageView = NSImageView(frame: CGRect(x: (bounds.width - 80) / 2, y: 105, width: 80, height: 80))
        iconImageView.image = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage
        addSubview(iconImageView)
        
        let titleLabel = NSTextField(frame: CGRect(x: 0, y: 55, width: bounds.width, height: 30))
        titleLabel.stringValue = "LangSwitcher"
        titleLabel.font = NSFont.boldSystemFont(ofSize: 21)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        addSubview(titleLabel)
        
        let subtitleLabel = NSTextField(frame: CGRect(x: 0, y: 30, width: bounds.width, height: 20))
        subtitleLabel.stringValue = "by Eyal Yaakobi  ·  v1.4"
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.60)
        subtitleLabel.alignment = .center
        subtitleLabel.isBezeled = false
        subtitleLabel.drawsBackground = false
        subtitleLabel.isEditable = false
        subtitleLabel.isSelectable = false
        addSubview(subtitleLabel)
    }
}

class SplashWindowController: NSWindowController {
    private static var current: SplashWindowController?
    
    static func show() {
        let controller = SplashWindowController()
        current = controller
        controller.showSplash()
    }
    
    convenience init() {
        let window = SplashWindow(
            contentRect: CGRect(x: 0, y: 0, width: 340, height: 210),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.alphaValue = 0.0
        
        self.init(window: window)
    }
    
    func showSplash() {
        guard let window = self.window else { return }
        
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? .zero
        let x = screenFrame.origin.x + (screenFrame.width - 340) / 2
        let y = screenFrame.origin.y + (screenFrame.height - 210) / 2
        window.setFrame(CGRect(x: x, y: y, width: 340, height: 210), display: true)
        
        let contentView = SplashView(frame: CGRect(x: 0, y: 0, width: 340, height: 210))
        window.contentView = contentView
        
        window.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            window.animator().alphaValue = 1.0
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.35
                    window.animator().alphaValue = 0.0
                }, completionHandler: {
                    window.close()
                    SplashWindowController.current = nil
                })
            }
        })
    }
}
