import Foundation

public final class FileHistoryStore: HistoryStore, @unchecked Sendable {
    public struct Storage: Codable {
        let items: [ClipboardItem]
    }

    private let fileURL: URL
    private let maxItemsProvider: () -> Int
    private let queue = DispatchQueue(label: "clipboardmenu.history", qos: .userInitiated)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var internalItems: [ClipboardItem] = []

    public init(fileURL: URL, maxItemsProvider: @escaping () -> Int) {
        self.fileURL = fileURL
        self.maxItemsProvider = maxItemsProvider
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    @discardableResult
    public func load() -> [ClipboardItem] {
        queue.sync {
            defer { trimAndPersistIfNeeded() }

            guard let data = try? Data(contentsOf: fileURL),
                  let storage = try? decoder.decode(Storage.self, from: data) else {
                internalItems = []
                return internalItems
            }

            internalItems = storage.items
            return internalItems
        }
    }

    public func add(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        queue.sync {
            internalItems.removeAll { $0.text == trimmedText }
            internalItems.insert(ClipboardItem(text: trimmedText), at: 0)
            trimAndPersistIfNeeded()
        }
    }

    public func clear() {
        queue.sync {
            internalItems = []
            persist()
        }
    }

    public func items() -> [ClipboardItem] {
        queue.sync { internalItems }
    }

    public func update(maxItems: Int) {
        queue.sync {
            let clamped = AppSettings.clampedMaxItems(maxItems)
            if internalItems.count > clamped {
                internalItems = Array(internalItems.prefix(clamped))
                persist()
            }
        }
    }

    private func trimAndPersistIfNeeded() {
        let maxItems = AppSettings.clampedMaxItems(maxItemsProvider())
        if internalItems.count > maxItems {
            internalItems = Array(internalItems.prefix(maxItems))
        }
        persist()
    }

    private func persist() {
        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let storage = Storage(items: internalItems)
            let data = try encoder.encode(storage)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Keep app functional even if persistence fails.
        }
    }
}
