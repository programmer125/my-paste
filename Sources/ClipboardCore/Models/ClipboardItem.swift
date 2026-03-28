import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public static let maxNoteLength = 120

    public let id: UUID
    public let text: String
    public let copiedAt: Date
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case copiedAt
        case note
    }

    public init(id: UUID = UUID(), text: String, copiedAt: Date = Date(), note: String? = nil) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.note = Self.sanitizedNote(note)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let text = try container.decode(String.self, forKey: .text)
        let copiedAt = try Self.decodeCopiedAt(from: container)
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        self.init(id: id, text: text, copiedAt: copiedAt, note: note)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(copiedAt, forKey: .copiedAt)
        try container.encodeIfPresent(note, forKey: .note)
    }

    public static func sanitizedNote(_ note: String?) -> String? {
        guard let note else { return nil }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.count <= maxNoteLength {
            return trimmed
        }
        return String(trimmed.prefix(maxNoteLength))
    }

    private static func decodeCopiedAt(from container: KeyedDecodingContainer<CodingKeys>) throws -> Date {
        if let copiedAt = try? container.decode(Date.self, forKey: .copiedAt) {
            return copiedAt
        }

        if let referenceInterval = try? container.decode(Double.self, forKey: .copiedAt) {
            return Date(timeIntervalSinceReferenceDate: referenceInterval)
        }

        if let rawValue = try? container.decode(String.self, forKey: .copiedAt) {
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let formatterWithoutFractionalSeconds = ISO8601DateFormatter()
            formatterWithoutFractionalSeconds.formatOptions = [.withInternetDateTime]

            if let copiedAt = formatterWithFractionalSeconds.date(from: rawValue)
                ?? formatterWithoutFractionalSeconds.date(from: rawValue) {
                return copiedAt
            }
        }

        throw DecodingError.dataCorruptedError(
            forKey: .copiedAt,
            in: container,
            debugDescription: "Unsupported copiedAt date format."
        )
    }
}
