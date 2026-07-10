import Carbon

/// Whether the keyboard is producing something other than standard half-width
/// alphanumeric.
///
/// A single IME (ATOK, Kotoeri, ...) keeps one input source while switching
/// between direct Roman input and kana or other modes, so we read the input
/// *mode* rather than the source id. Only the shared Roman mode types plain
/// ASCII; every other mode does not.
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

    // Plain keyboard layouts (US, ...) expose no input mode and type standard
    // alphanumeric. An input method exposes a mode; only its direct Roman mode
    // is standard, so anything else (kana, katakana, full-width, other scripts)
    // shows the badge.
    guard let mode = property(kTISPropertyInputModeID) else { return .roman }
    return mode == "com.apple.inputmethod.Roman" ? .roman : .japanese
}
