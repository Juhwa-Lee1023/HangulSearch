# HangulSearch
[![stability-beta](https://img.shields.io/badge/stability-beta-33bbff.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#beta)




`HangulSearch`는 다양한 방식의 한글 검색을 지원하는 스위프트 라이브러리입니다. 
<br/>
다양한 검색 모드를 활용하여 한글 텍스트 데이터에 대한 유연한 검색 기능을 구현할 수 있습니다.


## 기능

### 검색
- **초성 검색**: 사용자가 입력한 초성에 맞는 데이터를 검색합니다.
- **자동 완성**: 사용자의 입력에 기반한 자동 완성 결과를 제공합니다.
- **전체 문자열 검색**: 입력된 전체 문자열을 포함하는 데이터를 검색합니다.
- **종합 검색 모드**: 초성 검색과 자동 완성을 결합하여 더 넓은 범위의 검색을 지원합니다.

### 정렬
- **기본**: 정렬을 수행하지 않음. 데이터 순서대로 반환
- **자모 순서**: 항목들을 한글 자모 순서대로 정렬
- **자모 역순**: 항목들을 한글 자모 역순으로 정렬
- **편집 거리**: Levenshtein(편집 거리)을 기준으로 가장 유사한 결과 순으로 항목을 정렬합니다.
- **일치 위치**: 항목 내에서 검색어가 나타나는 위치를 기준으로 정렬합니다. 검색어가 항목에서 더 앞쪽에 위치할수록 우선 순위가 높습니다.


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
struct Person {
    var name: String
    var age: Int
}

let persons = [Person(name: "철수", age: 25), Person(name: "영희", age: 22)]
var searchEngine: HangulSearch<Person>?
searchEngine = HangulSearch(items: persons, mode: .autocomplete, keySelector: { $0.name })
```
<br/>

`isEqual` 사용 방법
`isEqual`은 검색 결과에서 중복된 항목을 제거할 때 사용됩니다. 기본적으로 `keySelector`를 통해 항목을 비교하지만, 특정 상황에서 두 항목의 부가적인 속성을 추가적으로 비교해 중복 여부를 판단해야 할 때 `isEqual`을 사용할 수 있습니다.

사용해야 하는 경우
- 중복 제거가 필요한 경우: 검색 결과에 동일한 항목이 여러 번 포함될 가능성이 있는 경우, isEqual을 사용하여 중복을 제거할 수 있습니다.
- 객체 비교: 단순히 keySelector로 추출한 값이 동일하더라도, 객체의 다른 속성(예: age나 id)을 기준으로 추가적으로 비교해야 할 때 유용합니다.

예를 들어, Person 객체 배열에서 이름이 같지만 나이가 다른 경우, 단순히 name으로만 비교하면 중복된 이름 중 하나만 반환될 수 있습니다. 이때 `isEqual`을 사용하여 age 속성까지 비교하면 중복된 이름이 있더라도 하나만 반환되는 것을 방지할 수 있습니다.

`isEqual` 사용 예시

```swift
struct Person {
    var name: String
    var age: Int
}

let persons = [
    Person(name: "철수", age: 25),
    Person(name: "철수", age: 30),
    Person(name: "영희", age: 22)
]

var searchEngine: HangulSearch<Person>?
searchEngine = HangulSearch(
    items: persons,
    mode: .containsMatch,
    keySelector: { $0.name },
    isEqual: { $0.age == $1.age }  // 추가로 age까지 비교하여 중복을 방지
)

let results = searchEngine?.searchItems(input: "철수")
// 결과: ["철수(25)", "철수(30)"]

```

### 검색 모드별 사용 방법

#### 1. 초성 검색 (`chosungAndFullMatch`)

초성 검색은 입력된 초성에 맞는 결과를 찾습니다. 예를 들어, "ㅊㅅ"을 입력하면 "철수"와 같은 결과가 반환됩니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .chosungAndFullMatch, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "ㅊㅅ")
    // results?.map { $0.name } = ["김철수", "이철수", "박철수", "최철수", "최성수", "최상욱", "정철수", "강철수", "초철수", "초성수", "초상욱", "윤철수", "장철수", "임철수"]
```
<details>
  <summary>클릭하여 동영상 보기</summary>

https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/9f5e0f28-d8ab-4010-9b58-79eafb35b798

</details>




#### 2. 전체 문자열 검색 (containsMatch)
전체 문자열 검색은 입력된 문자열이 포함된 모든 항목을 반환합니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .containsMatch, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "철수")
    // results?.map { $0.name } = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수"]
```

<details>
  <summary>클릭하여 동영상 보기</summary>



https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/8bdc8091-03d9-4c84-b56a-8f58cc5ef8f1



</details>



#### 3. 자동 완성 검색 (autocomplete)
자동 완성은 입력한 문자열이 포함된 항목들을 찾습니다. 예를 들어, "쵳"으로 검색하면 "최철수"와 같은 결과를 얻을 수 있습니다.

```swift
    let searchEngine = HangulSearch(items: persons, mode: .autocomplete, keySelector: { $0.name })
    let results = searchEngine?.searchItems(input: "쵳")
    // results?.map { $0.name } = ["최철수"]
```
<details>
  <summary>클릭하여 동영상 보기</summary>



https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/d8d3693b-0dc0-49e9-8117-df131ec20154



</details>


#### 4. 종합 검색 모드 (combined)
종합 검색 모드는 초성 검색, 전체 문자열 검색, 자동 완성 검색을 결합하여 더 많은 검색 결과를 제공합니다. 이 모드는 다양한 입력 형태에 대해 가장 광범위한 검색 결과를 반환합니다.

<details>
  <summary>클릭하여 동영상 보기</summary>


https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/94652207-6896-488f-af8c-db273312becd




</details>


### 정렬 기능 사용 방법

#### 1. 자모 순서 정렬 (hangulOrder)
검색 결과를 한글 자모 순서에 따라 정렬합니다. 예를 들어, "ㄱ", "ㄴ", "ㄷ" 순서로 결과가 나타납니다.

```swift
searchEngine?.changeSortMode(mode: .hangulOrder)
let results = searchEngine?.searchItems(input: "철수")
// 결과가 한글 자모 순서대로 정렬됩니다.
```

#### 2. 자모 역순 정렬 (hangulOrderReversed)
검색 결과를 한글 자모 순서의 역순으로 정렬합니다. 예를 들어, "ㅎ", "ㅍ", "ㅌ" 순서로 결과가 나타납니다.

```swift
searchEngine?.changeSortMode(mode: .hangulOrderReversed)
let results = searchEngine?.searchItems(input: "철수")
// 결과가 한글 자모 역순으로 정렬됩니다.
```

#### 3. 편집 거리 정렬 (editDistance)
검색어와 항목 간의 편집 거리(Levenshtein Distance)를 기준으로 가장 유사한 항목부터 정렬합니다. 검색어가 완전히 일치하지 않더라도, 가장 가까운 단어들이 상위에 노출됩니다.

```swift
searchEngine?.changeSortMode(mode: .editDistance)
let results = searchEngine?.searchItems(input: "철수")
// 검색어와 가장 유사한 결과부터 순차적으로 정렬됩니다.
```

#### 4. 일치 위치 정렬 (matchPosition)
항목 내에서 검색어가 나타나는 위치를 기준으로 정렬합니다. 검색어가 항목 내에서 앞에 나타날수록 우선순위가 높습니다.

```swift
searchEngine?.changeSortMode(mode: .matchPosition)
let results = searchEngine?.searchItems(input: "철")
// "철"이 앞부분에 위치하는 항목이 먼저 표시됩니다.
```

#### 5. 정렬 없이 기본 순서 유지 (none)
정렬 없이 기본 데이터 순서대로 결과를 반환합니다.

```swift
searchEngine?.changeSortMode(mode: .none)
let results = searchEngine?.searchItems(input: "철수")
// 데이터가 입력된 순서대로 반환됩니다.
```



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





