import Carbon

/// Whether the keyboard is currently in a Japanese conversion mode.
///
/// We look at the input *mode* rather than the input source id, because a single
/// IME (ATOK, Kotoeri, ...) keeps the same source while switching between kana
/// input and direct alphanumeric input. The mode ids below are Apple's standard
/// values shared across IMEs, so this stays vendor independent.
enum IMEState {
    case japanese
    case roman
}

func currentIMEState() -> IMEState {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return .roman
    }

    func property(_ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    // Preferred signal: the input mode distinguishes あ (kana) from 英数 (Roman)
    // within one Japanese IME.
    if let mode = property(kTISPropertyInputModeID) {
        if mode == "com.apple.inputmethod.Roman" {
            return .roman
        }
        if mode.contains("Japanese") {
            return .japanese
        }
    }

    // Fallback for sources that expose no mode (plain keyboard layouts, or an
    // IME sitting in its base state).
    if let id = property(kTISPropertyInputSourceID), id.contains("Japanese") {
        return .japanese
    }

    return .roman
}
