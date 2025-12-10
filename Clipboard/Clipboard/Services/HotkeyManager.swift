import AppKit
import Carbon
import Combine

final class HotkeyManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private static let defaultKeyCode: UInt32 = numericCast(kVK_ANSI_V)
    private static let defaultModifiers: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
    
    typealias Handler = () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: Handler?

    func register(keyCode: UInt32 = HotkeyManager.defaultKeyCode,
                  modifiers: UInt32 = HotkeyManager.defaultModifiers,
                  handler: @escaping Handler) {
        unregister()
        self.handler = handler

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { (next, event, userData) -> OSStatus in
            guard let userData = userData else { return CallNextEventHandler(next, event) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handler?()
            return noErr
        }, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandler)

        let signature: OSType = 0x434C4250 // "CLBP"
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Hotkey registration failed: \(status)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handlerRef = eventHandler {
            RemoveEventHandler(handlerRef)
            eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}

