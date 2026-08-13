# gpi-prm (Swift Package)

본 저장소는 `gpi-prm` PRM(실내 측위 진출입)의 외부 연동을 위한 **배포 전용 릴리즈 저장소(Release Repository)**이다.  
사전 컴파일(Pre-compiled)된 정적 `XCFramework` 형태의 바이너리를 SPM(Swift Package Manager) 포맷으로 독립 제공한다.  
iOS 실기기(arm64) 및 시뮬레이터(arm64, x86_64) 빌드를 모두 지원하며,  
`gpi-prm.xcframework` 내부의 `VERSION_X.X.X` 파일로 배포 버전을 확인할 수 있다.

---

## 프로젝트 연동 및 사용 방법 (Usage)

`Prm` 은 `Prm.create(name:callback:)` 로 인스턴스를 만들고,  
`pushEvent(x:y:z:)` 로 좌표를 주입하며,  
판단된 진출입 결과는 생성 시 넘긴 `PrmCallback` 으로 통지된다.

### 1. Xcode 외부 패키지(SPM) 연동
1. 타겟 앱을 연 상태로 Xcode 상단 메뉴 **[File] ➡ [Add Package Dependencies...]** 를 클릭한다.
2. 검색창(Search or Enter Package URL)에 아래 SPM 배포 전용 저장소 주소를 입력한다.  
   `https://github.com/Geoplan-Mobile/gpi-prm`
3. **Dependency Rule** 을 설정한 뒤 **[Add Package]** 로 연동을 완료한다.

### 2. Prm 인스턴스 생성 (콜백 필수)
`PrmCallback` 구현체를 만들어 `Prm.create(name:callback:)` 에 넘긴다.  
콜백은 생성 시 필수이며 인스턴스에 고정된다. `name` 은 로그·콜백 식별용이라 인스턴스마다 다른 이름을 준다.

```swift
import gpi_prm

final class MyPrmService: PrmCallback {
    lazy var prm: Prm = Prm.create(name: "site1", callback: self)

    // MARK: - PrmCallback (백그라운드 큐에서 호출됨 → UI 갱신은 main 으로 디스패치)
    // 첫 파라미터 prmName 으로 어느 인스턴스(공간)의 이벤트인지 구분한다.
    func onStart(prmName: String) {}
    func onStop(prmName: String) {}
    func onError(prmName: String, msg: String) {}
    func onReceivedInout(prmName: String, inoutStr: String, areaName: String) {
        // inoutStr: "IN" | "OUT"
        print("[\(prmName)] \(inoutStr) area=\(areaName)")
    }
}
```

### 3. 영역 데이터로 시작 및 좌표 주입
`AreaInfo`를 구성하고 `start(areaInfoList:)` 로 시작, 측위 좌표를 `pushEvent(x:y:z:)` 로 주입한다. 

```swift
let area = AreaInfo.Builder(name: "영역 A", points: [   // name·points 필수, 폴리곤 자동 폐합
        CGPoint(x: 0,  y: 0),
        CGPoint(x: 0,  y: 10),
        CGPoint(x: 10, y: 10),
        CGPoint(x: 10, y: 0),
    ])
    // --- 아래는 모두 선택(생략 시 기본값) ---
    .inCount(1)             // 진입 확정에 필요한 감지 횟수 (기본 1)
    .inCountInterval(0)     // 연속 인정 최대 간격(초) (기본 0; inCount≥2면 1 이상 필수)
    .inDist(3.0)            // 연속 감지 간 이동 허용 거리(m) (기본 3.0)
    .outPeriod(0)           // 신호 두절 시 OUT 유예(초) (기본 0=비활성)
    .priority(1)            // 영역 겹칠 때 콜백 순서, 작을수록 먼저 (기본 1)
    .callInout(true)        // 이 영역의 진출입 콜백 호출 여부 (기본 true)
    .build()

prm.start(areaInfoList: [area])   // 유효하지 않은 영역은 onError 로 통지 후 건너뜀

// 측위 좌표 주입 → 영역 안이면 onReceivedInout(inoutStr: "IN", ...)
prm.pushEvent(x: 5, y: 5, z: 0)

prm.stop()
```

> 상태 가드: 실행 중의 `start`,정지 중의 `stop`과 `pushEvent` 는 무시되며 `onError` 로 통지한다.

---

## API 레퍼런스 (API Reference)

라이브러리에서 대외 개방(Public)된 핵심 타입의 기술 명세서이다.

### 클래스: `Prm`
PRM 엔진 컨트롤러. 진출입 판정의 모든 제어 진입점이다.

* **`static func create(name: String, callback: PrmCallback) -> Prm`**  
  인스턴스 생성. 호출마다 **독립 인스턴스**가 만들어지며, 콜백은 **필수**(인스턴스에 고정)다.  
  `name` 은 로그·식별용이며 `PrmCallback` 의 `prmName` 으로 전달된다.

* **`func isRunning() -> Bool`**  
  엔진 구동 여부. `start` 이후 `stop` 전까지 `true`.
* **`func start(areaInfoList: [AreaInfo])`**  
  입력된 영역 데이터로 엔진 구동을 시작 하고, 구동 시작이 되면 `onStart` 호출.  
  만약, isRunning()==true 인경우 무시하고 `onError`호출.  
  유효하지 영역이 입력된 경우 `onError`로 해당 영역 오류 통지 후 유효한 영역만 가지고 구동을 시작.  
* **`func pushEvent(x: Double, y: Double, z: Double)`**  
  태그 좌표 주입 (이벤트 발생 시마다 호출). isRunning()==false 면 무시하고 `onError`호출.
* **`func stop()`**  
  엔진 정지 → 완료 시 `onStop` 호출. isRunning()==false 면 무시하고 `onError`호출.

### 프로토콜: `PrmCallback` (`AnyObject`)
엔진 → 호스트 이벤트 통지 인터페이스. 콜백은 백그라운드 큐에서 호출되므로 UI 갱신은 메인 스레드로 디스패치 필수.   
모든 콜백의 첫 파라미터 `prmName` 은 이벤트를 보낸 인스턴스 이름.

* **`func onStart(prmName: String)`**  
  시작 완료.
* **`func onStop(prmName: String)`**  
  정지 완료.
* **`func onError(prmName: String, msg: String)`**  
  오류 통지.
* **`func onReceivedInout(prmName: String, inoutStr: String, areaName: String)`**  
  영역 진출입 발생. `inoutStr` 은 `"IN"` 또는 `"OUT"`, `areaName` 은 설정한 `AreaInfo.name`.

### 입력 모델: `AreaInfo` (영역)
**Builder 전용**(`AreaInfo.Builder(name:points:)…build()`). `name`·`points` 는 필수, 나머지는 기본값.

| 프로퍼티 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `name` | `String` | 필수 | 영역 이름 (콜백 `areaName`) |
| `points` | `[CGPoint]` | 필수 | 폴리곤 꼭짓점 (자동 폐합, 3점 이상) |
| `inCount` | `Int` | 1 | 진입 확정에 필요한 감지 횟수 (1=즉시) |
| `inCountInterval` | `Int` | 0 | 연속 인정 최대 간격(초, inCount≥2면 1 이상) |
| `inDist` | `Double` | 3.0 | 연속 감지 간 이동 허용 거리(m) |
| `outPeriod` | `Int` | 0 | 신호 두절 시 OUT 유예(초, 0=비활성) |
| `priority` | `Int` | 1 | 겹칠 때 콜백 순서(작을수록 먼저) |
| `callInout` | `Bool` | true | 진출입 콜백 호출 여부 |

> **진출입 판정**  
진출입 판단 규칙에 사용되는 AreaInfo 프로퍼티의 상세 내용은 [INOUT_case.md](INOUT_case.md) 참고

### 버전: `SDKConfig`
* **`static var version: String`**  
  현재 SDK 버전. (예: `"2.0.0"`)
