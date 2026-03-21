import ClipboardCore
import Foundation

@MainActor
final class PopupViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var selectedIndex = 0

    var selectedItem: ClipboardItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    func setItems(_ items: [ClipboardItem]) {
        self.items = items
        selectedIndex = 0
    }

    func moveSelectionUp() {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + items.count) % items.count
    }

    func moveSelectionDown() {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % items.count
    }
}
