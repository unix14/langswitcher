import Cocoa
import Carbon

extension Notification.Name {
    static let hotkeyStoreChanged = Notification.Name("HotkeyStoreChanged")
}

class HotkeyStore {
    static let shared = HotkeyStore()
    
    private let keyKeyCode = "hotkeyKeyCode"
    private let keyModifiers = "hotkeyModifiers"
    
    private init() {}
    
    var keyCode: CGKeyCode {
        let val = UserDefaults.standard.integer(forKey: keyKeyCode)
        if UserDefaults.standard.object(forKey: keyKeyCode) == nil {
            return 37 // Default to 'L'
        }
        return CGKeyCode(val)
    }
    
    var nsModifiers: NSEvent.ModifierFlags {
        let val = UserDefaults.standard.integer(forKey: keyModifiers)
        if UserDefaults.standard.object(forKey: keyModifiers) == nil {
            return [.command, .shift] // Default to ⌘⇧
        }
        return NSEvent.ModifierFlags(rawValue: UInt(val))
    }
    
    func save(keyCode: CGKeyCode, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(Int(keyCode), forKey: keyKeyCode)
        UserDefaults.standard.set(Int(modifiers.rawValue), forKey: keyModifiers)
        NotificationCenter.default.post(name: .hotkeyStoreChanged, object: nil)
    }
    
    var displayString: String {
        var str = ""
        let mods = nsModifiers
        if mods.contains(.control) { str += "⌃" }
        if mods.contains(.option) { str += "⌥" }
        if mods.contains(.shift) { str += "⇧" }
        if mods.contains(.command) { str += "⌘" }
        
        str += keyName(from: keyCode)
        return str
    }
    
    private func keyName(from code: CGKeyCode) -> String {
        switch code {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "↩"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "⌫"
        case 53: return "⎋"
        case 65: return "."
        case 67: return "*"
        case 69: return "+"
        case 71: return "⌧"
        case 75: return "/"
        case 76: return "⌅"
        case 78: return "-"
        case 81: return "="
        case 82: return "0"
        case 83: return "1"
        case 84: return "2"
        case 85: return "3"
        case 86: return "4"
        case 87: return "5"
        case 88: return "6"
        case 89: return "7"
        case 91: return "8"
        case 92: return "9"
        case 115: return "↖"
        case 116: return "⇞"
        case 117: return "⌦"
        case 119: return "↘"
        case 120: return "⇟"
        case 121: return "F1"
        case 122: return "F2"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            if let translated = translateKeyCode(code) {
                return translated.uppercased()
            }
            return "Key \(code)"
        }
    }
    
    private func translateKeyCode(_ code: CGKeyCode) -> String? {
        guard let inputSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue() else {
            return nil
        }
        let layoutDataRef = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
        guard let layoutData = layoutDataRef else {
            return nil
        }
        let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue()
        let keyLayoutPointer = CFDataGetBytePtr(data)
        let keyboardLayoutPtr = keyLayoutPointer.map { UnsafeRawPointer($0).assumingMemoryBound(to: UCKeyboardLayout.self) }
        
        var keysDown: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var realLength = 0
        
        // We use 0 as the translate mask if kUCKeyTranslateNoDeadKeysMask or kUCKeyTranslateNoDeadKeysBit cannot be resolved.
        let status = UCKeyTranslate(
            keyboardLayoutPtr,
            UInt16(code),
            UInt16(kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            0, // No dead keys bit mask or 0 is safe
            &keysDown,
            4,
            &realLength,
            &chars
        )
        if status == noErr && realLength > 0 {
            return String(utf16CodeUnits: chars, count: realLength)
        }
        return nil
    }
}
