import ClipboardCore
import Foundation

@MainActor
final class PopupViewModel: ObservableObject {
    struct NoteCommit {
        let itemID: UUID
        let note: String?
    }

    struct ScrollRequest: Equatable {
        enum Alignment: Equatable {
            case top
            case bottom
        }

        let itemID: UUID
        let alignment: Alignment
    }

    @Published private(set) var allItems: [ClipboardItem] = []
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var editingItemID: UUID?
    @Published var editingNoteText = ""
    @Published private(set) var searchQuery = ""
    @Published private(set) var isSearchFieldFocused = false
    @Published private(set) var hasKeyboardSelectionNavigation = false
    @Published private(set) var pendingScrollRequest: ScrollRequest?

    private let visibleItemCapacity = 4
    private var visibleWindowStartIndex = 0

    var isEditingNote: Bool {
        editingItemID != nil
    }

    var shouldHandleEnterAsSearchSubmit: Bool {
        isSearchFieldFocused && !hasKeyboardSelectionNavigation && !isEditingNote
    }

    var selectedItem: ClipboardItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    func loadForDisplay(_ items: [ClipboardItem]) {
        searchQuery = ""
        hasKeyboardSelectionNavigation = false
        pendingScrollRequest = nil
        cancelEditingNote()
        allItems = sortedByCopiedAtDesc(items)
        applyFilter(preferredSelectedID: allItems.first?.id)
    }

    func refreshItems(_ items: [ClipboardItem]) {
        let selectedID = selectedItem?.id
        allItems = sortedByCopiedAtDesc(items)
        applyFilter(preferredSelectedID: selectedID)
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        hasKeyboardSelectionNavigation = false
        applyFilter(preferredSelectedID: selectedItem?.id)
    }

    func setSearchFieldFocused(_ focused: Bool) {
        isSearchFieldFocused = focused
        if focused {
            hasKeyboardSelectionNavigation = false
        }
    }

    func submitSearch() {
        hasKeyboardSelectionNavigation = false
        applyFilter(preferredSelectedID: selectedItem?.id)
    }

    func moveSelectionUp() {
        guard !items.isEmpty else { return }
        hasKeyboardSelectionNavigation = true
        selectedIndex = (selectedIndex - 1 + items.count) % items.count
        updateVisibleWindowForKeyboardNavigation()
    }

    func moveSelectionDown() {
        guard !items.isEmpty else { return }
        hasKeyboardSelectionNavigation = true
        selectedIndex = (selectedIndex + 1) % items.count
        updateVisibleWindowForKeyboardNavigation()
    }

    func selectItem(_ itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        hasKeyboardSelectionNavigation = false
        if editingItemID != itemID {
            cancelEditingNote()
        }
        selectedIndex = index
    }

    func beginEditingNote(for itemID: UUID) {
        guard let item = items.first(where: { $0.id == itemID }) else { return }
        selectItem(itemID)
        editingItemID = itemID
        editingNoteText = item.note ?? ""
    }

    func cancelEditingNote() {
        editingItemID = nil
        editingNoteText = ""
    }

    @discardableResult
    func commitEditingNote() -> NoteCommit? {
        guard let itemID = editingItemID else { return nil }

        let normalizedNote = ClipboardItem.sanitizedNote(editingNoteText)
        updateLocalNote(for: itemID, note: normalizedNote)
        cancelEditingNote()
        return NoteCommit(itemID: itemID, note: normalizedNote)
    }

    func consumePendingScrollRequest() {
        pendingScrollRequest = nil
    }

    func prepareForDismissal() {
        isSearchFieldFocused = false
        hasKeyboardSelectionNavigation = false
        pendingScrollRequest = nil
        cancelEditingNote()
    }

    private func updateLocalNote(for itemID: UUID, note: String?) {
        guard let index = allItems.firstIndex(where: { $0.id == itemID }) else { return }
        let item = allItems[index]
        let updated = ClipboardItem(
            id: item.id,
            text: item.text,
            copiedAt: item.copiedAt,
            note: note
        )
        allItems[index] = updated
        applyFilter(preferredSelectedID: itemID)
    }

    private func applyFilter(preferredSelectedID: UUID?) {
        let keyword = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if keyword.isEmpty {
            items = allItems
        } else {
            let noteMatches = allItems.filter { item in
                guard let note = item.note else { return false }
                return note.localizedCaseInsensitiveContains(keyword)
            }
            let noteIDs = Set(noteMatches.map(\.id))
            let textMatches = allItems.filter { item in
                !noteIDs.contains(item.id) && item.text.localizedCaseInsensitiveContains(keyword)
            }
            items = noteMatches + textMatches
        }

        if items.isEmpty {
            selectedIndex = 0
            visibleWindowStartIndex = 0
            pendingScrollRequest = nil
            cancelEditingNote()
            return
        }

        if let preferredSelectedID,
           let index = items.firstIndex(where: { $0.id == preferredSelectedID }) {
            selectedIndex = index
        } else if !items.indices.contains(selectedIndex) {
            selectedIndex = 0
        }

        if let editingItemID,
           !items.contains(where: { $0.id == editingItemID }) {
            cancelEditingNote()
        }

        resetVisibleWindow()
    }

    private func sortedByCopiedAtDesc(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.sorted { lhs, rhs in
            lhs.copiedAt > rhs.copiedAt
        }
    }

    private func updateVisibleWindowForKeyboardNavigation() {
        guard let item = selectedItem else {
            pendingScrollRequest = nil
            return
        }

        if selectedIndex < visibleWindowStartIndex {
            visibleWindowStartIndex = selectedIndex
            pendingScrollRequest = ScrollRequest(itemID: item.id, alignment: .top)
            return
        }

        let visibleWindowEndIndex = visibleWindowStartIndex + visibleItemCapacity - 1
        if selectedIndex > visibleWindowEndIndex {
            visibleWindowStartIndex = selectedIndex - visibleItemCapacity + 1
            pendingScrollRequest = ScrollRequest(itemID: item.id, alignment: .bottom)
            return
        }

        pendingScrollRequest = nil
    }

    private func resetVisibleWindow() {
        guard let item = selectedItem else {
            visibleWindowStartIndex = 0
            pendingScrollRequest = nil
            return
        }

        let maxVisibleWindowStartIndex = max(items.count - visibleItemCapacity, 0)
        visibleWindowStartIndex = min(selectedIndex, maxVisibleWindowStartIndex)
        pendingScrollRequest = ScrollRequest(itemID: item.id, alignment: .top)
    }
}
