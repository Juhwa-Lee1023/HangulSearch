import Foundation

public class HangulSearch<T> {
    private typealias SearchEntry = (item: T, key: String)
    private typealias ProcessedSearchEntry = (item: T, key: String, originalKey: String)
    
    private struct SearchContext {
        let items: [SearchEntry]
        let chosung: [ProcessedSearchEntry]
        let decomposed: [ProcessedSearchEntry]
    }
    
    private let 초성_리스트: [Character] = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ",
        "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    private let 중성_리스트: [Character] = [
        "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
    ]
    
    /// 종성이 없는 경우에는 nil을 사용(예. 가, 나, 다)
    private let 종성_리스트: [Character?] = [
        nil, "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    /// 검색할 제네릭 데이터 배열
    private var items: [T]
    
    /// 한글 검색 모드
    /// - containsMatch: 검색어가 항목에 포함되는 경우를 찾음
    /// - chosungAndFullMatch: 초성 및 일치하는 글자를 기반으로 검색을 수행
    /// - autocomplete: 자동 완성 검색을 수행
    /// - combined: 여러 검색 모드를 결합하여 검색을 수행
    private var searchMode: HangulSearchMode
    
    /// 정렬 모드
    /// - hangulOrder: 항목들을 한글 자모 순서대로 정렬.
    /// - hangulOrderReversed: 항목들을 한글 자모 역순으로 정렬
    /// - editDistance: 검색어와 항목 간의 편집 거리(레벤슈타인 거리)를 기준으로 항목을 정렬. 이 모드는
    ///   검색어와 가장 유사한 항목을 우선적으로 보여주어 사용자가 관련성 높은 결과를 빠르게 인지할 수 있도록 합니다.
    /// - matchPosition: 항목 내에서 검색어가 나타나는 위치를 기준으로 정렬. 검색어가 항목 내에서 더 앞에 나타날수록
    ///   해당 항목이 우선적으로 정렬됩니다.
    /// - none: 정렬을 수행하지 않습니다.
    private var sortMode: SortMode
    
    /// 초성 분해된 항목들
    /// - 각 항목의 키(key)는 초성으로 분해된 문자열입니다.
    private var processedItemsChosung: [ProcessedSearchEntry] = []
    
    /// 복합 분해된 항목들
    /// - 각 항목의 키(key)는 복합 분해된 문자열입니다.
    private var processedItemsDecomposed: [ProcessedSearchEntry] = []
    
    /// 원본 키 캐시
    /// - normalizeToNFC가 false인 기본 경로에서 재사용합니다.
    private var cachedItems: [SearchEntry] = []
    
    /// 검색을 수행할 선택자를 선택
    private var keySelector: (T) -> String
    
    /// 추가적으로 비교를 실행할 선택자를 선택
    private var isEqual: ((T, T) -> Bool)?
    
    // MARK: Init
    /// - Parameters:
    ///   - items: 검색을 수행할 데이터의 배열
    ///   - searchMode: 한글 검색 모드. 기본값은 chosungAndFullMatch
    ///   - sortMode: 결과를 정렬하는 방식. 기본값은 .none
    ///   - keySelector: 각 항목에서 검색을 수행할 선택자를 선택하는 클로저
    ///   - isEqual: 두 항목 간의 keySelector 가 동일할 경우 추가적으로 비교를 실행할 선택자를 선택하는 클로저
    ///              제공된 경우, 검색 결과에서 중복을 피하기 위해 사용됨
    ///              keySelector: { $0.name },  // 'name'을 기준으로 비교
    ///              isEqual: { $0.age == $1.age }  // 'age'를 추가로 비교
    public init(items: [T], searchMode: HangulSearchMode = .chosungAndFullMatch, sortMode: SortMode = .none, keySelector: @escaping (T) -> String, isEqual: ((T, T) -> Bool)? = nil) {
        self.items = items
        self.searchMode = searchMode
        self.sortMode = sortMode
        self.keySelector = keySelector
        self.isEqual = isEqual
        preprocessItems()
    }
    
    /// 주어진 검색어에 따라 항목을 검색합니다.
    /// - Parameter input: 검색어
    /// - Returns: 검색 결과로서, 검색어에 맞는 항목의 배열을 반환
    public func searchItems(input: String) -> [T] {
        return searchItems(input: input, options: HangulSearchOptions())
    }
    
    /// 옵션을 적용하여 검색을 수행합니다.
    /// - Parameters:
    ///   - input: 검색어
    ///   - options: 검색 옵션
    /// - Returns: 검색 결과로서, 검색어에 맞는 항목의 배열을 반환
    public func searchItems(input: String, options: HangulSearchOptions) -> [T] {
        let normalizedInput = normalizeIfNeeded(input, enabled: options.normalizeToNFC)
        let minimumInputLength = max(0, options.minInputLength)
        
        if normalizedInput.isEmpty, options.emptyQueryBehavior == .returnEmpty {
            return []
        }
        
        if !normalizedInput.isEmpty, normalizedInput.count < minimumInputLength {
            return []
        }
        
        let effectiveMode = options.mode ?? searchMode
        let effectiveSortMode = options.sortMode ?? sortMode
        let context = buildSearchContext(mode: effectiveMode, normalizeToNFC: options.normalizeToNFC)
        let results: [SearchEntry]
        
        if normalizedInput.isEmpty {
            results = context.items
        } else {
            results = searchEntries(input: normalizedInput, mode: effectiveMode, context: context)
        }
        
        var finalResults = sortEntries(results, by: effectiveSortMode, input: normalizedInput)
        finalResults = applyPagination(to: finalResults, offset: options.offset, limit: options.limit)
        
        return finalResults.map(\.item)
    }
    
    /// 검색을 수행할 데이터를 변경, 변경된 항목에 대해 사전 처리를 수행
    /// - Parameter items: 새로운 항목의 배열
    public func changeItems(items: [T]) {
        self.items = items
        preprocessItems()
    }
    
    /// 검색을 수행할 데이터를 추가, 추가된 항목에 대해 사전 처리를 수행
    /// - Parameter items: 추가할 항목의 배열
    public func addItems(items: [T]) {
        self.items.append(contentsOf: items)
        preprocessItems()
    }
    
    /// 검색 모드를 변경, 변경된 모드에 따라 사전 처리를 수행
    /// - Parameter mode: 새로운 검색 모드
    public func changeSearchMode(mode: HangulSearchMode) {
        self.searchMode = mode
        preprocessItems()
    }
    
    /// 검색을 수행할 선택자를 변경, 변경된 선택자에 따라 사전 처리를 수행
    /// - Parameter keySelector: 새로운 선택자 클로저입니다.
    public func changeKeySelector(keySelector: @escaping (T) -> String) {
        self.keySelector = keySelector
        preprocessItems()
    }
    
    /// 정렬 모드를 변경
    /// - Parameter mode: 새로운 정렬 모드
    public func changeSortMode(mode: SortMode) {
        self.sortMode = mode
    }
}


extension HangulSearch {
    /// 검색 항목을 전처리하여 매번 추출을 할 필요가 없도록 함
    private func preprocessItems() {
        // 모드 전환 시 이전 전처리 결과가 남지 않도록 캐시를 초기화합니다.
        processedItemsChosung = []
        processedItemsDecomposed = []
        cachedItems = buildBaseEntries(normalizeToNFC: false)
        
        switch searchMode {
        case .chosungAndFullMatch:
            // 초성 모드일 때는 초성 키로 매핑하여 처리
            processedItemsChosung = buildChosungEntries(from: cachedItems)
            
        case .autocomplete:
            // 자동 완성 모드일 때는 한글을 분해하여 처리
            processedItemsDecomposed = buildDecomposedEntries(from: cachedItems)
            
        case .combined:
            // 종합 모드일 때는 초성 매핑과 한글 분해를 둘 다 수행
            processedItemsChosung = buildChosungEntries(from: cachedItems)
            processedItemsDecomposed = buildDecomposedEntries(from: cachedItems)
            
        default:
            // containsMatch 모드의 경우 사전 작업을 수행하지 않음
            return
        }
    }
    
    private func buildSearchContext(mode: HangulSearchMode, normalizeToNFC: Bool) -> SearchContext {
        if normalizeToNFC {
            let baseEntries = buildBaseEntries(normalizeToNFC: true)
            switch mode {
            case .containsMatch:
                return SearchContext(items: baseEntries, chosung: [], decomposed: [])
            case .chosungAndFullMatch:
                return SearchContext(items: baseEntries, chosung: buildChosungEntries(from: baseEntries), decomposed: [])
            case .autocomplete:
                return SearchContext(items: baseEntries, chosung: [], decomposed: buildDecomposedEntries(from: baseEntries))
            case .combined:
                return SearchContext(
                    items: baseEntries,
                    chosung: buildChosungEntries(from: baseEntries),
                    decomposed: buildDecomposedEntries(from: baseEntries)
                )
            }
        }
        
        let baseEntries = cachedItems.isEmpty ? buildBaseEntries(normalizeToNFC: false) : cachedItems
        
        if mode == searchMode {
            switch mode {
            case .containsMatch:
                return SearchContext(items: baseEntries, chosung: [], decomposed: [])
            case .chosungAndFullMatch:
                return SearchContext(items: baseEntries, chosung: processedItemsChosung, decomposed: [])
            case .autocomplete:
                return SearchContext(items: baseEntries, chosung: [], decomposed: processedItemsDecomposed)
            case .combined:
                return SearchContext(items: baseEntries, chosung: processedItemsChosung, decomposed: processedItemsDecomposed)
            }
        }
        
        switch mode {
        case .containsMatch:
            return SearchContext(items: baseEntries, chosung: [], decomposed: [])
        case .chosungAndFullMatch:
            return SearchContext(items: baseEntries, chosung: buildChosungEntries(from: baseEntries), decomposed: [])
        case .autocomplete:
            return SearchContext(items: baseEntries, chosung: [], decomposed: buildDecomposedEntries(from: baseEntries))
        case .combined:
            return SearchContext(
                items: baseEntries,
                chosung: buildChosungEntries(from: baseEntries),
                decomposed: buildDecomposedEntries(from: baseEntries)
            )
        }
    }
    
    private func buildBaseEntries(normalizeToNFC: Bool) -> [SearchEntry] {
        return items.map { item in
            let key = normalizeIfNeeded(keySelector(item), enabled: normalizeToNFC)
            return (item: item, key: key)
        }
    }
    
    private func normalizeIfNeeded(_ value: String, enabled: Bool) -> String {
        if enabled {
            return value.precomposedStringWithCanonicalMapping
        }
        return value
    }
    
    private func buildChosungEntries(from entries: [SearchEntry]) -> [ProcessedSearchEntry] {
        return entries.map { entry in
            (item: entry.item, key: makeChosungKey(from: entry.key), originalKey: entry.key)
        }
    }
    
    private func makeChosungKey(from key: String) -> String {
        return key.compactMap { char -> Character? in
            if let index = getChosungIndex(char) {
                return 초성_리스트[index]
            }
            return nil
        }.map(String.init).joined()
    }
    
    private func buildDecomposedEntries(from entries: [SearchEntry]) -> [ProcessedSearchEntry] {
        return entries.map { entry in
            (item: entry.item, key: makeDecomposedKey(from: entry.key), originalKey: entry.key)
        }
    }
    
    private func makeDecomposedKey(from key: String) -> String {
        return key.flatMap(decomposeKorean).map(String.init).joined()
    }
    
    private func searchEntries(input: String, mode: HangulSearchMode, context: SearchContext) -> [SearchEntry] {
        // 검색 모드에 따라 적절한 검색 메서드를 선택하여 결과를 반환
        switch mode {
        case .containsMatch:
            return searchByFullChar(input: input, entries: context.items)
        case .chosungAndFullMatch:
            // 검색어에 따라 어떤 검색을 수행할지 결정. 초성으로만 되어 있지 않으면, 일치하는 문자열 기반 검색 수행
            return isPureChosung(input: input)
                ? searchByChosung(input: input, entries: context.chosung)
                : searchByFullChar(input: input, entries: context.items)
        case .autocomplete:
            return searchByAutocomplete(input: input, entries: context.decomposed)
        case .combined:
            return searchByCombined(input: input, context: context)
        }
    }
    
    /// 초성 검색을 수행하여 입력된 초성을 포함하는 항목을 반환
    /// - Parameter input: 검색어로 사용된 초성
    /// - Returns: 입력된 초성을 포함하는 항목의 배열을 반환
    private func searchByChosung(input: String, entries: [ProcessedSearchEntry]) -> [SearchEntry] {
        return entries.filter { _, key, _ in
            key.contains(input)
        }.map { entry in
            (item: entry.item, key: entry.originalKey)
        }
    }
    
    /// 완전 일치 검색을 수행하여 입력된 문자열을 포함하는 항목을 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 문자열을 포함하는 항목의 배열을 반환
    private func searchByFullChar(input: String, entries: [SearchEntry]) -> [SearchEntry] {
        return entries.filter { _, key in
            key.localizedCaseInsensitiveContains(input)
        }
    }
    
    /// 자동 완성 검색을 수행하여 입력된 문자열을 포함하는 항목을 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 문자열을 포함하는 항목의 배열을 반환
    private func searchByAutocomplete(input: String, entries: [ProcessedSearchEntry]) -> [SearchEntry] {
        let decomposedInput = input.flatMap(decomposeKorean).map { String($0) }.joined()
        
        return entries.filter { _, decomposedKey, _ in
            decomposedKey.localizedCaseInsensitiveContains(decomposedInput)
        }.map { entry in
            (item: entry.item, key: entry.originalKey)
        }
    }
    
    /// 종합 검색을 수행하여 여러 검색 모드의 결과를 결합하여 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 초성 및 자동 완성에 해당하는 항목의 배열을 반환
    private func searchByCombined(input: String, context: SearchContext) -> [SearchEntry] {
        var results = [SearchEntry]()
        let fullMatchResults = searchByFullChar(input: input, entries: context.items)
        
        // 중복 검사는 두 가지 방식으로 수행될 수 있음
        // 1. 사용자가 `isEqual` 클로저를 제공한 경우: 이 클로저는 `keySelector` 결과와 추가적으로 비교를 위해 선언한 선택자를 이용해
        //    두 객체가 일치하는지를 검사
        // 2. 사용자가 `isEqual` 클로저를 제공하지 않은 경우: `keySelector`의 결과만을 사용하여 일치하는지 검사
        //
        // `isUnique` 변수는 주어진 아이템이 결과 배열에 이미 존재하는지 여부를 결정.
        //  이 값이 `true`일 경우, 아이템은 결과 배열에 추가되고, `false`일 경우 추가되지 않음
        let appendIfUnique: (SearchEntry) -> Void = { entry in
            let isUnique: Bool
            if let customIsEqual = self.isEqual {
                isUnique = !results.contains { otherEntry in
                    otherEntry.key == entry.key && customIsEqual(otherEntry.item, entry.item)
                }
            } else {
                isUnique = !results.contains(where: { $0.key == entry.key })
            }
            if isUnique {
                results.append(entry)
            }
        }
        
        // 1. 완전 일치 검색 결과를 결과 배열에 추가
        fullMatchResults.forEach(appendIfUnique)
        // 2. 초성 입력인 경우 초성 검색 결과를 결과 배열에 추가
        if isPureChosung(input: input) {
            searchByChosung(input: input, entries: context.chosung).forEach(appendIfUnique)
        }
        // 3. 자동 완성 검색 결과를 결과 배열에 추가
        searchByAutocomplete(input: input, entries: context.decomposed).forEach(appendIfUnique)
        return results
    }
    
    /// 주어진 문자에 대한 초성의 인덱스를 반환
    /// - Parameter char: 초성을 찾을 문자
    /// - Returns: 주어진 문자의 초성 인덱스를 반환. 한글이 아닌 경우 nil을 반환
    private func getChosungIndex(_ char: Character) -> Int? {
        let unicode = char.unicodeScalars.first!.value
        if isValidHangulUnicode(unicode) {
            // 한글 음절의 유니코드 값에서 '가'의 유니코드 값을 뺀 결과를 계산 후 초성 인덱스를 추출
            return Int((unicode - 0xAC00) / 28 / 21)
        }
        return nil
    }
    
    /// 주어진 문자열이 순수한 초성인지 여부를 판단
    /// - Parameter input: 판단할 문자열
    /// - Returns: 입력된 문자열이 순수한 초성으로만 구성되어 있는 경우 true를 반환
    private func isPureChosung(input: String) -> Bool {
        return input.allSatisfy { 초성_리스트.contains($0) }
    }
    
    /// 주어진 문자를 한글 문자의 구성 요소로 분해
    /// - Parameter char: 분해할 문자
    /// - Returns: 주어진 문자를 한글 문자의 초성, 중성, 종성으로 분해한 결과를 반환
    private func decomposeKorean(_ char: Character) -> [Character] {
        let unicode = char.unicodeScalars.first!.value
        if isValidHangulUnicode(unicode) {
            let base = unicode - 0xAC00 // 한글 음절의 유니코드 값에서 '가'의 유니코드 값을 뺀 결과를 계산
            let chosungIndex = Int(base / (21 * 28)) // 초성 인덱스를 추출
            let jungsungIndex = Int((base % (21 * 28)) / 28) // 중성 인덱스를 추출
            let jongsungIndex = Int(base % 28) // 종성 인덱스를 추출
            var result = [초성_리스트[chosungIndex], 중성_리스트[jungsungIndex]]
            if let jongsung = 종성_리스트[jongsungIndex] {
                result.append(jongsung)
            }
            return result
        }
        return [char]
    }
    
    /// 주어진 유니코드 값이 한글 음절의 유효한 범위 내에 있는지 확인
    /// 범위는 '가'부터 '힣'까지
    /// - Parameter unicode: 검사할 유니코드 값
    /// - Returns: 주어진 유니코드 값이 한글 음절의 범위 내에 있으면 true를 반환하고, 그렇지 않으면 false를 반환
    private func isValidHangulUnicode(_ unicode: UInt32) -> Bool {
        let startUnicode: UInt32 = 0xAC00
        let endUnicode: UInt32 = 0xD7A3
        return (unicode >= startUnicode) && (unicode <= endUnicode)
    }
    
    private func sortEntries(_ entries: [SearchEntry], by sortMode: SortMode, input: String) -> [SearchEntry] {
        switch sortMode {
        case .hangulOrder:
            return sortEntriesByHangulOrder(entries: entries)
        case .hangulOrderReversed:
            return sortEntriesByHangulOrderReversed(entries: entries)
        case .editDistance:
            return sortEntriesByEditDistance(to: input, entries: entries)
        case .matchPosition:
            return sortEntriesByMatchPosition(input: input, entries: entries)
        case .none:
            return entries
        }
    }
    
    /// 항목들을 한글 자모 순서대로 정렬
    /// - Parameter entries: 정렬할 항목 배열
    /// - Returns: 정렬된 항목 배열
    private func sortEntriesByHangulOrder(entries: [SearchEntry]) -> [SearchEntry] {
        return entries.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
    }
    
    /// 항목들을 한글 자모 역순으로 정렬
    /// - Parameter entries: 정렬할 항목 배열
    /// - Returns: 정렬된 항목 배열
    private func sortEntriesByHangulOrderReversed(entries: [SearchEntry]) -> [SearchEntry] {
        return entries.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedDescending
        }
    }
    
    /// 검색 입력에 대해 편집 거리를 기반으로 항목을 정렬
    /// - Parameters:
    ///   - target: 검색어
    ///   - entries: 정렬할 항목 배열
    /// - Returns: 정렬된 항목 배열
    private func sortEntriesByEditDistance(to target: String, entries: [SearchEntry]) -> [SearchEntry] {
        let scoredEntries = entries.enumerated().map { index, entry in
            (index: index, entry: entry, distance: levenshteinDistance(from: entry.key, to: target))
        }
        
        return scoredEntries.sorted { lhs, rhs in
            if lhs.distance == rhs.distance {
                return lhs.index < rhs.index
            }
            return lhs.distance < rhs.distance
        }.map { $0.entry }
    }
    
    /// 레벤슈타인 편집 거리 계산 함수
    /// 두 문자열 간의 레벤슈타인 편집 거리를 계산합니다.
    /// 본 구현 방법에 대한 자세한 설명은 다음 웹사이트를 참고
    /// https://lovit.github.io/nlp/2018/08/28/levenshtein_hangle/
    /// - Parameters:
    ///   - s1: 첫 번째 문자열
    ///   - s2: 두 번째 문자열
    /// - Returns: 두 문자열 간의 편집 거리
    private func levenshteinDistance(from s1: String, to s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var distanceMatrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m {
            distanceMatrix[i][0] = i
        }
        for j in 0...n {
            distanceMatrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = (s1[i - 1].lowercased() == s2[j - 1].lowercased()) ? 0 : 1
                distanceMatrix[i][j] = min(
                    distanceMatrix[i - 1][j] + 1,
                    distanceMatrix[i][j - 1] + 1,
                    distanceMatrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return distanceMatrix[m][n]
    }
    
    /// 입력 문자열과 일치하는 위치를 기준으로 항목을 정렬
    /// - Parameters:
    ///   - input: 검색어
    ///   - entries: 정렬할 항목 배열
    /// - Returns: 일치하는 위치를 기준으로 정렬된 항목 배열
    private func sortEntriesByMatchPosition(input: String, entries: [SearchEntry]) -> [SearchEntry] {
        let scoredEntries = entries.enumerated().map { index, entry in
            let matchIndex = entry.key.range(of: input, options: .caseInsensitive)?.lowerBound.utf16Offset(in: entry.key) ?? Int.max
            return (index: index, entry: entry, matchIndex: matchIndex)
        }
        
        return scoredEntries.sorted { lhs, rhs in
            if lhs.matchIndex == rhs.matchIndex {
                return lhs.index < rhs.index
            }
            return lhs.matchIndex < rhs.matchIndex
        }.map { $0.entry }
    }
    
    private func applyPagination(to entries: [SearchEntry], offset: Int, limit: Int?) -> [SearchEntry] {
        let safeOffset = max(0, offset)
        
        guard safeOffset < entries.count else {
            return []
        }
        
        let sliced = entries[safeOffset...]
        
        guard let limit else {
            return Array(sliced)
        }
        
        let safeLimit = max(0, limit)
        
        guard safeLimit > 0 else {
            return []
        }
        
        return Array(sliced.prefix(safeLimit))
    }
    
}
