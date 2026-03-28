import AppKit
import ClipboardCore
import Foundation
import SwiftUI

@MainActor
final class PopupController {
    typealias HistoryProvider = () -> [ClipboardItem]
    typealias ErrorHandler = (String) -> Void
    typealias NoteUpdateHandler = (UUID, String?) -> Void

    private let caretLocator: CaretLocator
    private let pasteExecutor: PasteExecutor
    private let historyProvider: HistoryProvider
    var onError: ErrorHandler
    var onUpdateNote: NoteUpdateHandler

    private let viewModel = PopupViewModel()

    private var panel: HistoryPanel?
    private var hostingView: NSHostingView<PopupView>?

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
        self.onUpdateNote = { _, _ in }
    }

    func show() {
        let items = historyProvider()
        guard !items.isEmpty else {
            NSSound.beep()
            return
        }

        viewModel.loadForDisplay(items)
        let panel = ensurePanel()

        let origin = preferredOrigin(for: panel.frame.size)
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        viewModel.prepareForDismissal()
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> HistoryPanel {
        if let panel {
            return panel
        }

        let panel = makePanel()
        let hostingView = NSHostingView(
            rootView: PopupView(
                viewModel: viewModel,
                onSaveNote: { [weak self] itemID, note in
                    self?.saveNote(itemID: itemID, note: note)
                }
            )
        )
        panel.contentView = hostingView

        self.hostingView = hostingView
        self.panel = panel
        return panel
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
            self?.handleKey(event) ?? false
        }

        return panel
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 126:
            viewModel.moveSelectionUp()
            return true
        case 125:
            viewModel.moveSelectionDown()
            return true
        case 36, 76:
            if viewModel.shouldHandleEnterAsSearchSubmit {
                return false
            }
            if viewModel.isEditingNote {
                if let commit = viewModel.commitEditingNote() {
                    saveNote(itemID: commit.itemID, note: commit.note)
                }
            } else {
                copySelectionAndClose()
            }
            return true
        case 53:
            if viewModel.isEditingNote {
                viewModel.cancelEditingNote()
            } else {
                hide()
            }
            return true
        default:
            return false
        }
    }

    private func saveNote(itemID: UUID, note: String?) {
        onUpdateNote(itemID, note)
        viewModel.refreshItems(historyProvider())
    }

    private func copySelectionAndClose() {
        guard let item = viewModel.selectedItem else { return }

        do {
            try pasteExecutor.copy(text: item.text)
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
