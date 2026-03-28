import ClipboardCore
import Foundation

#if canImport(XCTest)
import XCTest

final class FileHistoryStoreTests: XCTestCase {
    func testAddShouldDeduplicateAndMoveToTop() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 3)

        store.add("one")
        store.add("two")
        store.add("three")
        store.add("two")

        XCTAssertEqual(store.items().map(\.text), ["two", "three", "one"])
    }

    func testAddShouldIgnoreBlankText() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 3)

        store.add("   ")
        store.add("\n\t")

        XCTAssertTrue(store.items().isEmpty)
    }

    func testLoadShouldRestorePersistedItems() {
        let fileURL = temporaryFileURL()

        do {
            let store = makeStore(fileURL: fileURL, maxItems: 5)
            store.add("first")
            store.add("second")
            store.flush()
        }

        let reloaded = makeStore(fileURL: fileURL, maxItems: 5)
        let loadedItems = reloaded.load()

        XCTAssertEqual(loadedItems.count, 2)
        XCTAssertEqual(loadedItems.map(\.text), ["second", "first"])
    }

    func testUpdateMaxItemsShouldTrimExistingItems() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 5)

        store.add("one")
        store.add("two")
        store.add("three")
        store.add("four")

        store.update(maxItems: 2)

        XCTAssertEqual(store.items().map(\.text), ["four", "three"])
    }

    func testAddShouldPreserveExistingNoteWhenTextDeduplicates() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 5)

        store.add("hello")
        guard let first = store.items().first else {
            XCTFail("Expected first item")
            return
        }

        store.updateNote(itemID: first.id, note: "  keep me  ")
        store.add("hello")

        guard let updated = store.items().first else {
            XCTFail("Expected updated first item")
            return
        }

        XCTAssertEqual(updated.note, "keep me")
    }

    func testUpdateNoteShouldPersistAcrossReload() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 5)

        store.add("persist me")
        guard let first = store.items().first else {
            XCTFail("Expected first item")
            return
        }

        store.updateNote(itemID: first.id, note: "note value")

        store.flush()

        let reloaded = makeStore(fileURL: fileURL, maxItems: 5)
        let items = reloaded.load()

        XCTAssertEqual(items.first?.note, "note value")
    }

    func testLoadShouldDecodeLegacyItemWithoutNote() throws {
        let fileURL = temporaryFileURL()
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let payload = """
        {
          "items": [
            {
              "copiedAt": "2026-03-21T00:00:00Z",
              "id": "11111111-1111-1111-1111-111111111111",
              "text": "legacy"
            }
          ]
        }
        """
        guard let payloadData = payload.data(using: .utf8) else {
            XCTFail("Expected payload data")
            return
        }
        try payloadData.write(to: fileURL)

        let store = makeStore(fileURL: fileURL, maxItems: 5)
        let items = store.load()

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "legacy")
        XCTAssertNil(items.first?.note)
    }

    func testUpdateNoteShouldTrimAndClampLength() {
        let fileURL = temporaryFileURL()
        let store = makeStore(fileURL: fileURL, maxItems: 5)

        store.add("note-limit")
        guard let first = store.items().first else {
            XCTFail("Expected first item")
            return
        }

        let longNote = String(repeating: "a", count: ClipboardItem.maxNoteLength + 30)
        store.updateNote(itemID: first.id, note: "  \(longNote)  ")

        guard let updated = store.items().first else {
            XCTFail("Expected updated first item")
            return
        }

        XCTAssertEqual(updated.note?.count, ClipboardItem.maxNoteLength)
    }

    func testFlushShouldPersistPendingChangesBeforeDebounceFires() {
        let fileURL = temporaryFileURL()
        let store = FileHistoryStore(
            fileURL: fileURL,
            maxItemsProvider: { 5 },
            persistDebounceInterval: 60
        )

        store.add("flush me")
        store.flush()

        let reloaded = makeStore(fileURL: fileURL, maxItems: 5)
        let items = reloaded.load()

        XCTAssertEqual(items.map(\.text), ["flush me"])
    }

    private func makeStore(fileURL: URL, maxItems: Int) -> FileHistoryStore {
        FileHistoryStore(fileURL: fileURL, maxItemsProvider: { maxItems }, persistDebounceInterval: 0)
    }

    private func temporaryFileURL() -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return folder.appendingPathComponent("history.json", isDirectory: false)
    }
}
#else
struct FileHistoryStoreTestsUnavailable {}
#endif
