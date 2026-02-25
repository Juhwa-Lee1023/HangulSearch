import Foundation

public struct HangulSearchOptions: Hashable {
    public enum EmptyQueryBehavior: Hashable {
        case returnEmpty
        case returnAll
    }
    
    public var mode: HangulSearchMode?
    public var sortMode: SortMode?
    public var limit: Int?
    public var offset: Int
    public var minInputLength: Int
    public var normalizeToNFC: Bool
    public var emptyQueryBehavior: EmptyQueryBehavior
    
    public init(
        mode: HangulSearchMode? = nil,
        sortMode: SortMode? = nil,
        limit: Int? = nil,
        offset: Int = 0,
        minInputLength: Int = 1,
        normalizeToNFC: Bool = false,
        emptyQueryBehavior: EmptyQueryBehavior = .returnEmpty
    ) {
        self.mode = mode
        self.sortMode = sortMode
        self.limit = limit
        self.offset = offset
        self.minInputLength = minInputLength
        self.normalizeToNFC = normalizeToNFC
        self.emptyQueryBehavior = emptyQueryBehavior
    }
}
