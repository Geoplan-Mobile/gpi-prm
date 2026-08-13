# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [2.0.0] - 2026-08-14

### 변경됨 (Breaking) — 사용 측 코드 수정 필요
- **인스턴스 생성 방식 변경**  
싱글턴 `PrmFactory.getInstance()` → **`Prm.create(name:callback:)`**.  
호출마다 **독립 인스턴스**가 만들어져 동시 다수 구동 가능.  

- **콜백 시그니처 변경**  
`PrmCallback` 의 모든 콜백 첫 파라미터에 **`prmName`** 추가(인스턴스 구분용).  
진출입 콜백은 **`onReceivedInout(prmName:inoutStr:areaName:)`** 로,  
기존 `tagId`·`workspaceId` 제거 `workspaceName` 은 **`areaName`** 으로 변경.

- **`AreaInfo` 생성 방식 변경**  
직접 생성 후 프로퍼티 대입 → **Builder 를 통한 생성**(`AreaInfo.Builder(name:points:)…build()`).  
`name`·`points` 는 필수, 기타 속성은 세팅하지 않으면 기본값 이 적용. 

- **`start` / `pushEvent` 시그니처 변경**  
`start(areaInfoList:wallInfoList:)` → **`start(areaInfoList:)`** `wallInfoList` 제거.  
`pushEvent(spaceId:tagId:x:y:z:)` → **`pushEvent(x:y:z:)`**. `spaceId`·`tagId` 제거.

- **Prm 서버 연동 시작 제거**  
`start(baseUrl:…)` 계열이 제거. 영역은 이제 **직접 주입(`start(areaInfoList:)`)만** 지원.

- **벽(Wall) 기능 제거**  
공개 타입 `WallInfo` 와 벽 통과 판정이 제거.

### 추가됨
- **멀티 인스턴스 Prm**  
서로 다른 공간을 독립 인스턴스로 동시에 운용 가능. 하나의 콜백을 여러 인스턴스에 공유해도 `prmName` 으로 구분 가능.

- **영역 검증**  
`start` 시 주입된 유효하지 않은 영역(AreaInfo)은 `onError`로 통지 후 Skip.(유효한 영역만 진행). 이름이 중복시 첫 번째만 사용.

- **상태 가드**  
실행 중 `start`, 정지 중 `stop`, 정지 중 `pushEvent` 호출은 무시하고 `onError` 로 통지.

- **로깅**  
진출입·생명주기·콜백 지점의 로그를 `os.Logger` + 파일 로그(`Documents/gpi-prm/yyyyMMdd.txt`)로 남긴다. 

### 수정됨 (동작 개선)
- **겹침 영역 IN 판정 오류 개선**  
여러 영역이 겹친 위치의 좌표 주입시 진입 카운트 누적 오류 수정.  
모든 영역은 타 영역과 **완전히 독립적으로** IN/OUT 판단을 수행한다.

- **진입 누적 강화**  
누적중 영역에 안·밖 좌표가 번갈아 올 때 밖좌표는 무시하고 시간·거리 조건만으로 누적 하던 것을 보완.  
누적 중 영역은 그 영역 **밖 좌표가 오면 진입 누적을 1 감소**시킨다 -> IN 판정 지연.  

- **이탈 타이머 영역별 독립 처리**  
영역이 `outPeriod` 만료로 OUT 될 때 타 영역도 함께 OUT되던 오류 해결.이 제 해당 영역만 OUT.

## [1.1.0] - 2026-07-13

### 변경됨 (Breaking)
- **공개 API 이름 변경** — 라이브러리 명칭을 MIOC → PRM 으로 통일. **사용 측 코드 수정 필요.**
  - `MIoc` → `Prm`, `MIocFactory` → `PrmFactory`, `MIocCallback` → `PrmCallback`
  - 진입점: `MIocFactory.getInstance()` → `PrmFactory.getInstance()`
  - `AreaInfo` · `WallInfo` · `SDKConfig` 는 **이름·속성·시그니처 모두 동일** (변경 없음)

### 수정됨
- **진출입 판정 동시성 크래시 수정** — 좌표 진출입 판정(`processInArea`)과 이탈 정리 타이머(`outPeriodCheck`)가 서로 다른 스레드에서 같은 내부 컬렉션(진입 태그 목록/마지막 감지 시각)을 동시에 수정해 발생하던 data race(`EXC_BAD_ACCESS`)를 수정. 재진입 락으로 두 경로를 상호배제.

### 참고
- 판정 로직·동작, 요구사항(iOS 15.0+), 의존성(GEOSwift 11.2.0)은 1.0.0 과 동일.
- 버전 식별 파일: `gpi-prm.xcframework/VERSION_1.1.0`.

## [1.0.0] - 2026-06-24

### 추가됨
- **최초 배포**: PRM(실내 측위 진출입 / 지오펜싱) 엔진.
  - 공개 API: `MIoc`, `MIocFactory`, `MIocCallback`, `AreaInfo`, `WallInfo`, `SDKConfig`.
  - 태그 좌표 스트림(`pushEvent`)을 받아 영역/벽 진출입(IN/OUT)을 판정해 `MIocCallback.onReceivedInout` 으로 통지.
  - 시작: `start(areaInfoList:wallInfoList:)` 로 영역/벽 데이터를 직접 주입.
- **iOS Simulator 지원**: `xcframework` 에 `ios-arm64`(device) + `ios-arm64_x86_64-simulator` 슬라이스 포함.
- **버전 식별 파일**: `gpi-prm.xcframework/VERSION_1.0.0` 동봉 — 연동 없이도 배포 버전 확인 가능.

### 의존성
- `GEOSwift` 11.2.0 (및 transitive `geos` 9.0.0) — 영역 in/out 기하 연산. wrapper 패키지의 carrier 가 짊어져 호스트 앱에 자동 전파되므로, 사용 측은 GEOSwift 를 별도 선언하지 않는다.

### 요구사항
- deployment target **iOS 15.0+**.
