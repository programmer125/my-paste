import Foundation

public final class FileHistoryStore: HistoryStore, @unchecked Sendable {
    public struct Storage: Codable {
        let items: [ClipboardItem]
    }

    private let fileURL: URL
    private let maxItemsProvider: () -> Int
    private let persistDebounceInterval: TimeInterval
    private let queue = DispatchQueue(label: "clipboardmenu.history", qos: .utility)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var internalItems: [ClipboardItem] = []
    private var pendingPersistWorkItem: DispatchWorkItem?
    private var isDirty = false

    public init(
        fileURL: URL,
        maxItemsProvider: @escaping () -> Int,
        persistDebounceInterval: TimeInterval = 0.3
    ) {
        self.fileURL = fileURL
        self.maxItemsProvider = maxItemsProvider
        self.persistDebounceInterval = persistDebounceInterval
        encoder.dateEncodingStrategy = .iso8601
    }

    deinit {
        flush()
    }

    @discardableResult
    public func load() -> [ClipboardItem] {
        queue.sync {
            cancelPendingPersistLocked()

            guard let data = try? Data(contentsOf: fileURL),
                  let storage = try? decoder.decode(Storage.self, from: data) else {
                internalItems = []
                isDirty = false
                return internalItems
            }

            internalItems = storage.items
            if trimItemsLocked(limit: configuredMaxItemsLocked()) {
                persistIfDirtyLocked()
            } else {
                isDirty = false
            }
            return internalItems
        }
    }

    public func add(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        queue.sync {
            let preservedNote = internalItems.first(where: { $0.text == trimmedText })?.note
            internalItems.removeAll { $0.text == trimmedText }
            internalItems.insert(ClipboardItem(text: trimmedText, copiedAt: Date(), note: preservedNote), at: 0)
            _ = trimItemsLocked(limit: configuredMaxItemsLocked())
            markDirtyAndSchedulePersistLocked()
        }
    }

    public func updateNote(itemID: UUID, note: String?) {
        let normalizedNote = ClipboardItem.sanitizedNote(note)

        queue.sync {
            guard let index = internalItems.firstIndex(where: { $0.id == itemID }) else {
                return
            }

            let item = internalItems[index]
            let updated = ClipboardItem(
                id: item.id,
                text: item.text,
                copiedAt: item.copiedAt,
                note: normalizedNote
            )
            guard updated != item else { return }

            internalItems[index] = updated
            markDirtyAndSchedulePersistLocked()
        }
    }

    public func clear() {
        queue.sync {
            guard !internalItems.isEmpty else { return }
            internalItems = []
            markDirtyAndSchedulePersistLocked()
        }
    }

    public func items() -> [ClipboardItem] {
        queue.sync { internalItems }
    }

    public func update(maxItems: Int) {
        queue.sync {
            if trimItemsLocked(limit: maxItems) {
                markDirtyAndSchedulePersistLocked()
            }
        }
    }

    public func flush() {
        queue.sync {
            cancelPendingPersistLocked()
            persistIfDirtyLocked()
        }
    }

    private func configuredMaxItemsLocked() -> Int {
        max(0, maxItemsProvider())
    }

    private func trimItemsLocked(limit: Int) -> Bool {
        let clampedLimit = max(0, limit)
        guard internalItems.count > clampedLimit else { return false }

        internalItems = Array(internalItems.prefix(clampedLimit))
        isDirty = true
        return true
    }

    private func markDirtyAndSchedulePersistLocked() {
        isDirty = true
        cancelPendingPersistLocked()

        guard persistDebounceInterval > 0 else {
            persistIfDirtyLocked()
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.persistIfDirtyLocked()
        }
        pendingPersistWorkItem = workItem
        queue.asyncAfter(deadline: .now() + persistDebounceInterval, execute: workItem)
    }

    private func cancelPendingPersistLocked() {
        pendingPersistWorkItem?.cancel()
        pendingPersistWorkItem = nil
    }

    private func persistIfDirtyLocked() {
        pendingPersistWorkItem = nil
        guard isDirty else { return }

        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let storage = Storage(items: internalItems)
            let data = try encoder.encode(storage)
            try data.write(to: fileURL, options: .atomic)
            isDirty = false
        } catch {
            // Keep app functional even if persistence fails.
        }
    }
}
