# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [2.0.0] - 2026-08-14

### 변경됨 (Breaking) — 사용 측 코드 수정 필요
- **인스턴스 생성 방식 변경**  
싱글턴 `Prm.getInstance()` → **`Prm.create(name, callback)`**.  
호출마다 **독립 인스턴스**가 만들어져 동시 다수 구동 가능. 콜백은 **생성 시 필수**(`null` 이면 `IllegalArgumentException`)이며, 별도 `setCallback` 은 제거.

- **콜백 시그니처 변경**  
`PrmCallback` 의 모든 콜백 첫 파라미터에 **`prmName`** 추가(인스턴스 구분용).  
진출입 콜백은 **`onReceivedInout(prmName, inout, areaName)`** 로,  
기존 `tagId`·`workspaceId` 제거, `workspaceName` 은 **`areaName`** 으로 변경.

- **`AreaInfo` 생성 방식 변경**  
`new AreaInfo()` + setter → **Builder 를 통한 생성**(`AreaInfo.builder(name, points)…build()`).  
`name`·`points` 는 필수, 기타 속성은 세팅하지 않으면 기본값 적용(생성 후 불변).

- **`start` / `pushEvent` 시그니처 변경**  
`start(List<AreaInfo>, List<WallInfo>)` → **`start(List<AreaInfo>)`** (`wallInfoList` 제거).  
`pushEvent(spaceId, tagId, x, y, z)` → **`pushEvent(x, y, z)`** (`spaceId`·`tagId` 제거).

- **서버 연동 시작 제거**  
서버에서 영역을 받아오던 `start(baseUrl, …)` 계열 제거. 영역은 이제 **직접 주입(`start(List<AreaInfo>)`)만** 지원.

- **벽(Wall) 기능 제거**  
공개 타입 `WallInfo` 와 벽 통과 판정이 제거.

### 추가됨
- **멀티 인스턴스 Prm**  
서로 다른 공간을 독립 인스턴스로 동시에 운용 가능. 하나의 콜백을 여러 인스턴스에 공유해도 `prmName` 으로 구분 가능.

- **영역 검증**  
`start` 시 주입된 유효하지 않은 영역(AreaInfo)은 `onError` 로 통지 후 Skip(유효한 영역만 진행). 이름이 중복 시 첫 번째만 사용.

- **상태 가드**  
실행 중 `start`, 정지 중 `stop`, 정지 중 `pushEvent` 호출은 무시하고 `onError` 로 통지.

### 수정됨 (동작 개선)
- **겹침 영역 IN 판정 오류 개선**  
여러 영역이 겹친 위치의 좌표 주입 시 진입 카운트 누적 오류 수정.  
모든 영역은 타 영역과 **완전히 독립적으로** IN/OUT 판단을 수행한다.

- **진입 누적 강화**  
누적 중 영역에 안·밖 좌표가 번갈아 올 때 밖 좌표를 무시하고 시간·거리 조건만으로 누적하던 것을 보완.  
누적 중 영역은 그 영역 **밖 좌표가 오면 진입 누적을 1 감소**시킨다 → IN 판정 지연.

- **이탈 타이머 영역별 독립 처리**  
한 영역이 `outPeriod` 만료로 OUT 될 때 타 영역까지 함께 OUT되던 오류 해결. 이제 해당 영역만 OUT.

### 요구사항
- minSdk 27 / compileSdk 32.

## [1.1.0] - 2026-07-13
- **1.0.7 과 동일 산출물의 재배포** — 라이브러리명·공개 API 변경을 마이너 버전에 명시적으로 반영.

## [1.0.7] - 2026-07-13

### 변경됨 (Breaking) — 라이브러리명 / 공개 API
- 라이브러리명 `gpa-mioc` → **`gpa-prm`** (Maven 좌표 `kr.geoplan.android.lib:gpa-prm`, 패키지 `kr.co.geoplan.android.lib.prm`).
- 공개 타입: `MIoc` → **`Prm`**, `MIocCallback` → **`PrmCallback`** (`AreaInfo`·`WallInfo` 는 이름 동일).

### 수정됨
- 진출입 판정과 이탈 타이머의 동시성 크래시(data race) 수정.
