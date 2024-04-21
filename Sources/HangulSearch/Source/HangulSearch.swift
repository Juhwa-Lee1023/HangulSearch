import Foundation

public class HangulSearch<T> {
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
    
    /// 초성 분해된 항목들
    /// - 각 항목의 키(key)는 초성으로 분해된 문자열입니다.
    private var processedItemsChosung: [(item: T, key: String)] = []
    
    /// 복합 분해된 항목들
    /// - 각 항목의 키(key)는 복합 분해된 문자열입니다.
    private var processedItemsDecomposed: [(item: T, key: String)] = []
    
    /// 검색을 수행할 선택자를 선택
    private var keySelector: (T) -> String
    
    // MARK: Init
    /// - Parameters:
    ///   - items: 검색을 수행할 데이터의 배열
    ///   - mode: 한글 검색 모드. 기본값은 chosungAndFullMatch
    ///   - keySelector: 각 항목에서 검색을 수행할 선택자를 선택하는 클로저
    public init(items: [T], mode: HangulSearchMode = .chosungAndFullMatch, keySelector: @escaping (T) -> String) {
        self.items = items
        self.searchMode = mode
        self.keySelector = keySelector
        preprocessItems()
    }
    
    /// 주어진 검색어에 따라 항목을 검색합니다.
    /// - Parameter input: 검색어
    /// - Returns: 검색 결과로서, 검색어에 맞는 항목의 배열을 반환
    public func searchItems(input: String) -> [T] {
        if input.isEmpty {
            // TODO: 검색어가 비어있을 때, 모드에 따라 반환 형태가 다르게 처리되어야 함.
            return []
        }
        
        // 검색 모드에 따라 적절한 검색 메서드를 선택하여 결과를 반환
        switch searchMode {
        case .containsMatch:
            return searchByFullChar(input: input)
        case .chosungAndFullMatch:
            // 검색어에 따라 어떤 검색을 수행할지 결정. 초성으로만 되어 있지 않으면, 일치하는 문자열 기반 검색 수행
            return isPureChosung(input: input) ?
            searchByChosung(input: input) :
            searchByFullChar(input: input)
        case .autocomplete:
            return searchByAutocomplete(input: input)
        case .combined:
            return searchByCombined(input: input)
        }
    }
    
    /// 검색을 수행할 데이터를 변경, 변경된 항목에 대해 사전 처리를 수행
    /// - Parameter items: 새로운 항목의 배열
    public func changeItems(items: [T]) {
        self.items = items
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
}


extension HangulSearch {
    /// 검색 항목을 전처리하여 매번 추출을 할 필요가 없도록 함
    private func preprocessItems() {
        switch searchMode {
        case .chosungAndFullMatch:
            // 초성 모드일 때는 초성 키로 매핑하여 처리
            processedItemsChosung = items.map { item in
                let key = keySelector(item)
                let chosungKey = key.compactMap { char -> Character? in
                    if let index = getChosungIndex(char) {
                        return 초성_리스트[index]
                    }
                    return nil
                }.map { String($0) }.joined()
                return (item, chosungKey)
            }
            
        case .autocomplete:
            // 자동 완성 모드일 때는 한글을 분해하여 처리
            processedItemsDecomposed = items.map { item in
                let key = keySelector(item)
                let decomposedKey = key.flatMap(decomposeKorean).map { String($0) }.joined()
                return (item, decomposedKey)
            }
            
        case .combined:
            // 종합 모드일 때는 초성 매핑과 한글 분해를 둘 다 수행
            processedItemsChosung = items.map { item in
                let key = keySelector(item)
                let chosungKey = key.compactMap { char -> Character? in
                    if let index = getChosungIndex(char) {
                        return 초성_리스트[index]
                    }
                    return nil
                }.map { String($0) }.joined()
                return (item, chosungKey)
            }
            
            processedItemsDecomposed = items.map { item in
                let key = keySelector(item)
                let decomposedKey = key.flatMap(decomposeKorean).map { String($0) }.joined()
                return (item, decomposedKey)
            }
            
        default:
            // containsMatch 모드의 경우 사전 작업을 수행하지 않음
            return
        }
    }
    
    /// 초성 검색을 수행하여 입력된 초성을 포함하는 항목을 반환
    /// - Parameter input: 검색어로 사용된 초성
    /// - Returns: 입력된 초성을 포함하는 항목의 배열을 반환
    private func searchByChosung(input: String) -> [T] {
        let results = processedItemsChosung.filter { _, key in
            key.contains(input)
        }.map { $0.item }
        return results
    }
    
    /// 완전 일치 검색을 수행하여 입력된 문자열을 포함하는 항목을 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 문자열을 포함하는 항목의 배열을 반환
    private func searchByFullChar(input: String) -> [T] {
        return items.filter { item in
            keySelector(item).contains(input)
        }
    }
    
    /// 자동 완성 검색을 수행하여 입력된 문자열과 시작하는 부분이 일치하는 항목을 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 문자열로 시작하는 항목의 배열을 반환
    private func searchByAutocomplete(input: String) -> [T] {
        let decomposedInput = input.flatMap(decomposeKorean).map { String($0) }.joined()
        
        return processedItemsDecomposed.filter { _, decomposedKey in
            decomposedKey.starts(with: decomposedInput)
        }.map { $0.item }
    }
    
    /// 종합 검색을 수행하여 여러 검색 모드의 결과를 결합하여 반환
    /// - Parameter input: 검색어로 사용될 문자열
    /// - Returns: 입력된 초성 및 자동 완성에 해당하는 항목의 배열을 반환
    private func searchByCombined(input: String) -> [T] {
        var results = [T]()
        
        // 1. 완전 일치 검색 결과를 결과 배열에 추가
        let containsMatches = searchByFullChar(input: input)
        results.append(contentsOf: containsMatches)
        
        // 2. 초성 검색 또는 완전 일치 검색 결과를 결과 배열에 추가
        let fullCharMatches = isPureChosung(input: input) ? searchByChosung(input: input) : searchByFullChar(input: input)
        for match in fullCharMatches {
            // 결과 배열에 중복된 항목이 없을 경우에만 추가
            if !results.contains(where: { keySelector($0) == keySelector(match) }) {
                results.append(match)
            }
        }
        
        // 3. 자동 완성 검색 결과를 결과 배열에 추가
        let autocompleteMatches = searchByAutocomplete(input: input)
        for match in autocompleteMatches {
            // 결과 배열에 중복된 항목이 없을 경우에만 추가
            if !results.contains(where: { keySelector($0) == keySelector(match) }) {
                results.append(match)
            }
        }
        
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

}