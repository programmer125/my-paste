import ClipboardCore
import Foundation

#if canImport(XCTest)
import XCTest

final class FileHistoryStoreTests: XCTestCase {
    func testAddShouldDeduplicateAndMoveToTop() {
        let fileURL = temporaryFileURL()
        let store = FileHistoryStore(fileURL: fileURL, maxItemsProvider: { 3 })

        store.add("one")
        store.add("two")
        store.add("three")
        store.add("two")

        XCTAssertEqual(store.items().map(\.text), ["two", "three", "one"])
    }

    func testAddShouldIgnoreBlankText() {
        let fileURL = temporaryFileURL()
        let store = FileHistoryStore(fileURL: fileURL, maxItemsProvider: { 3 })

        store.add("   ")
        store.add("\n\t")

        XCTAssertTrue(store.items().isEmpty)
    }

    func testLoadShouldRestorePersistedItems() {
        let fileURL = temporaryFileURL()

        do {
            let store = FileHistoryStore(fileURL: fileURL, maxItemsProvider: { 5 })
            store.add("first")
            store.add("second")
        }

        let reloaded = FileHistoryStore(fileURL: fileURL, maxItemsProvider: { 5 })
        let loadedItems = reloaded.load()

        XCTAssertEqual(loadedItems.count, 2)
        XCTAssertEqual(loadedItems.map(\.text), ["second", "first"])
    }

    func testUpdateMaxItemsShouldTrimExistingItems() {
        let fileURL = temporaryFileURL()
        let store = FileHistoryStore(fileURL: fileURL, maxItemsProvider: { 5 })

        store.add("one")
        store.add("two")
        store.add("three")
        store.add("four")

        store.update(maxItems: 2)

        XCTAssertEqual(store.items().map(\.text), ["four", "three"])
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
