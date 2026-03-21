import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let copiedAt: Date

    public init(id: UUID = UUID(), text: String, copiedAt: Date = Date()) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
    }
}
