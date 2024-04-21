# HangulSearch
 
`KoreanSearch`는 다양한 방식의 한글 검색을 지원하는 스위프트 라이브러리입니다. 
<br/>
다양한 검색 모드를 활용하여 한글 텍스트 데이터에 대한 유연한 검색 기능을 구현할 수 있습니다.


## 기능

- **초성 검색**: 사용자가 입력한 초성에 맞는 데이터를 검색합니다.
- **자동 완성**: 사용자의 입력에 기반한 자동 완성 결과를 제공합니다.
- **전체 문자열 검색**: 입력된 전체 문자열을 포함하는 데이터를 검색합니다.
- **종합 검색 모드**: 초성 검색과 자동 완성을 결합하여 더 넓은 범위의 검색을 지원합니다.


## 설치 방법


1. Xcode를 열고, 상단 메뉴에서 **File > Swift Packages > Add Package Dependency...** 를 선택합니다.
2. 검색창에 `HangulSearch`의 URL을 붙여넣습니다: `https://github.com/Juhwa-Lee1023/HangulSearch`
3. `main` 브랜치를 선택하여 설치합니다.
4. `Next`를 클릭한 후, `Finish`를 클릭하여 설치를 완료합니다.

## 사용 방법

`HangulSearch` 라이브러리를 사용하기 위해선, 우선 `HangulSearch` 인스턴스를 생성해야 합니다. 
<br/>
여기에는 검색할 데이터 배열과 검색 모드, 그리고 검색할 데이터의 속성를 추출하는 `keySelector` 클로저를 선언합니다.
<br/>

### 인스턴스 생성 예제

#### 문자열 배열을 요소로 하는 `HangulSearch` 인스턴스를 생성

```swift
var searchEngine: HangulSearch<String>?
searchEngine = HangulSearch(items: ["사과", "바나나", "포도"], mode: .containsMatch, keySelector: { $0 })
```

#### Person 객체 배열을 요소로 하는 `HangulSearch` 인스턴스 생성

```swift
var searchEngine: HangulSearch<Person>?
let personSearch = HangulSearch(items: persons, mode: .autocomplete, keySelector: { $0.name })
```
<br/>

### 검색 모드별 사용 방법

#### 1. 초성 검색 (`chosungAndFullMatch`)

초성 검색 모드에서는 사용자가 입력한 초성에 해당하는 항목을 찾습니다. 예를 들어, "ㅊㅅ"을 검색하면 "철수"가 포함된 모든 이름을 찾을 수 있습니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .chosungAndFullMatch, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "ㅊㅅ")
    // results?.map { $0.name } = ["김철수", "이철수", "박철수", "최철수", "최성수", "최상욱", "정철수", "강철수", "초철수", "초성수", "초상욱", "윤철수", "장철수", "임철수"]
```

#### 2. 전체 문자열 검색 (containsMatch)
전체 문자열 검색에서는 입력된 전체 문자열을 포함하는 항목을 반환합니다. 예를 들어, "철수"라는 문자열을 검색하면 이름 중 "철수"를 포함하는 모든 결과를 반환합니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .containsMatch, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "철수")
    // results?.map { $0.name } = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수"]
```

#### 3. 자동 완성 검색 (autocomplete)
자동 완성 검색에서는 사용자가 입력한 문자열로 시작하는 항목을 찾습니다. 예를 들어, "쵳"으로 검색하면 "최철수"와 같은 이름을 찾을 수 있습니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .autocomplete, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "쵳")
    // results?.map { $0.name } = ["최철수"]
```

#### 4. 종합 검색 모드 (combined)
결합 검색 모드에서는 초성 검색, 전체 문자열 검색, 자동 완성 검색을 조합하여 더 넓은 범위의 검색 결과를 제공합니다. 이 모드는 다양한 입력 형태에 대해 가장 광범위한 검색 결과를 반환합니다.

<br/>

[사용된 데이터](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/MockData/people.json)

<br/>

추가적으로 라이브러리의 기능을 이해하고 활용하기 위한 테스트 코드 예제를 참조하고 싶다면, [테스트 코드](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/HangulSearchTests.swift) 를 참고해주세요.




<br/>

## 기여하기

이 프로젝트에 기여하고 싶으시다면, Pull Request를 보내주시거나, Issues를 등록해 주세요. 모든 종류의 기여를 환영합니다!

<br/>

## 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다. 자세한 내용은 [LICENSE](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/LICENSE) 파일을 참조해주세요.





