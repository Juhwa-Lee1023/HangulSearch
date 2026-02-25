# HangulSearch
[![stability-beta](https://img.shields.io/badge/stability-beta-33bbff.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#beta)

`HangulSearch`는 Swift 기반 한글 검색 라이브러리입니다.  
초성 검색, 일반 문자열 검색, 자동 완성 검색, 복합 검색을 지원하며 결과 정렬/옵션/메타데이터 API를 제공합니다.

## 지원 환경
- iOS 11.0 이상
- macOS 10.13 이상
- watchOS 4.0 이상
- tvOS 11.0 이상

## 설치
### Xcode에서 추가
1. Xcode 상단 메뉴에서 **File > Swift Packages > Add Package Dependency...**를 선택합니다.
2. 저장소 URL `https://github.com/Juhwa-Lee1023/HangulSearch`를 입력합니다.
3. 브랜치 또는 버전 규칙을 선택합니다.
4. 패키지 추가를 완료합니다.

## 빠른 시작
```swift
import HangulSearch

struct Person {
    let name: String
    let age: Int
}

let people = [
    Person(name: "김철수", age: 25),
    Person(name: "이철수", age: 30),
    Person(name: "이영희", age: 22)
]

let engine = HangulSearch(
    items: people,
    searchMode: .combined,
    sortMode: .matchPosition,
    keySelector: { $0.name },
    isEqual: { $0.age == $1.age }
)

let legacyResults = engine.searchItems(input: "ㅊㅅ")
let optionResults = engine.searchItems(
    input: "철수",
    options: HangulSearchOptions(limit: 10, offset: 0)
)
let hits = engine.searchHits(
    input: "철수",
    options: HangulSearchOptions(sortMode: .editDistance)
)
```

## 공개 API
### 생성자
```swift
public init(
    items: [T],
    searchMode: HangulSearchMode = .chosungAndFullMatch,
    sortMode: SortMode = .none,
    keySelector: @escaping (T) -> String,
    isEqual: ((T, T) -> Bool)? = nil
)
```

### 검색
```swift
public func searchItems(input: String) -> [T]
public func searchItems(input: String, options: HangulSearchOptions) -> [T]
public func searchHits(input: String, options: HangulSearchOptions) -> [HangulSearchHit<T>]
```

### 갱신/설정 변경
```swift
public func changeItems(items: [T])
public func addItems(items: [T])
public func changeSearchMode(mode: HangulSearchMode)
public func changeKeySelector(keySelector: @escaping (T) -> String)
public func changeSortMode(mode: SortMode)
```

## 옵션 타입
### `HangulSearchOptions`
```swift
public struct HangulSearchOptions {
    public enum EmptyQueryBehavior { case returnEmpty, returnAll }

    public var mode: HangulSearchMode?
    public var sortMode: SortMode?
    public var limit: Int?
    public var offset: Int
    public var minInputLength: Int
    public var normalizeToNFC: Bool
    public var emptyQueryBehavior: EmptyQueryBehavior
}
```

기본값(1.x 호환):
- `mode: nil` (엔진 기본 모드 사용)
- `sortMode: nil` (엔진 기본 정렬 사용)
- `limit: nil` (제한 없음)
- `offset: 0`
- `minInputLength: 1`
- `normalizeToNFC: false` (legacy 동작 유지)
- `emptyQueryBehavior: .returnEmpty` (legacy 동작 유지)

### `HangulSearchHit<Item>`
- `item`: 원본 항목
- `matchKinds`: 매칭 종류 집합 (`.fullMatch`, `.chosungMatch`, `.autocompleteMatch`)
- `matchPosition`: `SortMode.matchPosition` 기준이 되는 시작 위치(없으면 `nil`)
- `editDistance`: `SortMode.editDistance` 계산값(없으면 `nil`)

## 검색 모드
### `containsMatch`
- `keySelector(item)` 값에 입력 문자열이 포함되는 항목을 검색합니다.
- 문자열 비교는 대소문자를 구분하지 않습니다.

### `chosungAndFullMatch`
- 입력이 순수 초성(예: `ㅊㅅ`)이면 초성 검색을 수행합니다.
- 입력이 초성이 아니면 `containsMatch`와 동일하게 동작합니다.

### `autocomplete`
- 입력/항목 문자열을 한글 자모로 분해한 뒤 포함 여부를 비교합니다.

### `combined`
- 전체 문자열 검색, 초성 검색(순수 초성 입력 시), 자동 완성 검색 결과를 순서대로 결합합니다.
- 중복 제거 키는 `keySelector` 결과이며, `isEqual`이 제공되면 추가 비교를 수행합니다.

## 정렬 모드
### `none`
- 입력 순서를 유지합니다.

### `hangulOrder`
- 한글 자모 기준 오름차순 정렬입니다.

### `hangulOrderReversed`
- 한글 자모 기준 내림차순 정렬입니다.

### `editDistance`
- 검색어와 항목 문자열의 Levenshtein distance 오름차순 정렬입니다.

### `matchPosition`
- 항목 내에서 검색어가 처음 일치하는 위치 오름차순 정렬입니다.

## 동작 계약 (1.x)
- 기존 API `searchItems(input:)`는 유지되며 기본 동작을 보존합니다.
- 기본 옵션에서 빈 입력은 빈 배열을 반환합니다.
- `searchItems(input:options:)` / `searchHits(input:options:)`는 Additive API입니다.
- `editDistance`/`matchPosition` 동률은 원본 검색 결과 순서를 tie-break로 사용합니다.
- `combined` 모드는 결과 중복 제거 후 `matchKinds`를 병합합니다.
- `normalizeToNFC`는 opt-in이며 기본값 `false`로 legacy 동작을 유지합니다.

## 성능 및 가변성 참고
- `changeItems`, `addItems`, `changeSearchMode`, `changeKeySelector` 호출 시 내부 전처리 캐시를 다시 구성합니다.
- 검색 입력이 동일해도 `sortMode`가 `editDistance`/`matchPosition`이면 입력 기준 계산 비용이 추가됩니다.
- `searchHits`는 정렬에 필요한 메타데이터를 한 번 계산해 결과에 재사용합니다.

## CI / 품질 게이트
- Pull Request 및 `main`/`codex/**` push에서 아래 잡을 실행합니다.
- `swift test --parallel`
- `swift test -c release`
- `swift test --sanitize=thread`
- benchmark smoke (`HangulSearchBenchmarkSmokeTests`)

## 참고 자료
- [테스트 데이터](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/MockData/people.json)
- [기본 테스트](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/HangulSearchTests.swift)
- [옵션 API 테스트](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/HangulSearchOptionsSearchTests.swift)
- [상세 결과 API 테스트](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/HangulSearchHitsTests.swift)

## 운영 문서
- [CHANGELOG](CHANGELOG.md)
- [MIGRATION](MIGRATION.md)
- [CONTRIBUTING](CONTRIBUTING.md)
- [SECURITY](SECURITY.md)

## 데모 영상
- 초성 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/9f5e0f28-d8ab-4010-9b58-79eafb35b798
- 전체 문자열 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/8bdc8091-03d9-4c84-b56a-8f58cc5ef8f1
- 자동 완성 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/d8d3693b-0dc0-49e9-8117-df131ec20154
- 종합 검색 모드: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/94652207-6896-488f-af8c-db273312becd

## 기여
이슈 등록 또는 Pull Request를 통해 기여할 수 있습니다.

## 라이선스
이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
