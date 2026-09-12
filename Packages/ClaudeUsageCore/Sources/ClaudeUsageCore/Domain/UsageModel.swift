import Foundation

public enum UsageModel: String, CaseIterable, Sendable {
    case sonnet
    case opus

    public init?(displayName: String?) {
        guard let name = displayName?.lowercased() else { return nil }
        let words = name.split(whereSeparator: { !$0.isLetter })
        guard let model = Self.allCases.first(where: { words.contains(Substring($0.rawValue)) }) else {
            return nil
        }
        self = model
    }
}
