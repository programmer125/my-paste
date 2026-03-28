import Foundation

public protocol HistoryStore: AnyObject {
    @discardableResult
    func load() -> [ClipboardItem]

    func add(_ text: String)
    func updateNote(itemID: UUID, note: String?)
    func clear()
    func items() -> [ClipboardItem]
    func update(maxItems: Int)
}
