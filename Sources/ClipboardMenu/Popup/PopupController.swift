import AppKit
import ClipboardCore
import Foundation
import SwiftUI

@MainActor
final class PopupController {
    typealias HistoryProvider = () -> [ClipboardItem]
    typealias ErrorHandler = (String) -> Void

    private let caretLocator: CaretLocator
    private let pasteExecutor: PasteExecutor
    private let historyProvider: HistoryProvider
    var onError: ErrorHandler

    private let viewModel = PopupViewModel()

    private var panel: HistoryPanel?

    init(
        caretLocator: CaretLocator,
        pasteExecutor: PasteExecutor,
        historyProvider: @escaping HistoryProvider,
        onError: @escaping ErrorHandler
    ) {
        self.caretLocator = caretLocator
        self.pasteExecutor = pasteExecutor
        self.historyProvider = historyProvider
        self.onError = onError
    }

    func show() {
        let items = historyProvider()
        guard !items.isEmpty else {
            NSSound.beep()
            return
        }

        viewModel.setItems(items)

        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }

        panel.contentView = NSHostingView(rootView: PopupView(viewModel: viewModel))

        let origin = preferredOrigin(for: panel.frame.size)
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> HistoryPanel {
        let panel = HistoryPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 430),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        panel.keyDownHandler = { [weak self] event in
            self?.handleKey(event)
        }

        return panel
    }

    private func handleKey(_ event: NSEvent) {
        switch event.keyCode {
        case 126:
            viewModel.moveSelectionUp()
        case 125:
            viewModel.moveSelectionDown()
        case 36, 76:
            pasteSelection()
        case 53:
            hide()
        default:
            break
        }
    }

    private func pasteSelection() {
        guard let item = viewModel.selectedItem else { return }

        do {
            try pasteExecutor.paste(text: item.text)
            hide()
        } catch {
            onError(error.localizedDescription)
        }
    }

    private func preferredOrigin(for size: CGSize) -> CGPoint {
        let anchor = caretLocator.currentAnchorPoint() ?? NSEvent.mouseLocation

        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let screen else { return anchor }

        let minX = screen.frame.minX + 10
        let maxX = screen.frame.maxX - size.width - 10
        let x = min(max(anchor.x - size.width / 2, minX), maxX)

        var y = anchor.y - size.height - 12
        if y < screen.frame.minY + 10 {
            y = anchor.y + 24
        }
        let maxY = screen.frame.maxY - size.height - 10
        y = min(max(y, screen.frame.minY + 10), maxY)

        return CGPoint(x: x, y: y)
    }
}
