import Foundation

public struct HangulSearchHit<Item> {
    public let item: Item
    public let matchKinds: Set<HangulMatchKind>
    public let matchPosition: Int?
    public let editDistance: Int?
    
    public init(
        item: Item,
        matchKinds: Set<HangulMatchKind>,
        matchPosition: Int? = nil,
        editDistance: Int? = nil
    ) {
        self.item = item
        self.matchKinds = matchKinds
        self.matchPosition = matchPosition
        self.editDistance = editDistance
    }
}
