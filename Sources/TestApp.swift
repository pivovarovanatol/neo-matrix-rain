import Cocoa
import ScreenSaver

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var saverView: NeoMatrixView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 1280, height: 720)

        window = NSWindow(
            contentRect: frame,
            styleMask:   [.titled, .closable, .miniaturizable, .resizable],
            backing:     .buffered,
            defer:       false)
        window.title = "Neo Matrix Rain – Preview (press Q to quit)"
        window.center()
        window.makeKeyAndOrderFront(nil)

        saverView = NeoMatrixView(frame: window.contentView!.bounds, isPreview: false)
        saverView.autoresizingMask = [.width, .height]
        window.contentView!.addSubview(saverView)

        saverView.startAnimation()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.charactersIgnoringModifiers == "q" { NSApp.terminate(nil) }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

