# gpi-prm (Release)

iOS용 모바일 PRM(실내 측위 진출입 / 지오펜싱) 라이브러리 — **바이너리 배포 저장소**.

이 저장소는 컴파일된 `gpi-prm.xcframework` 만 SPM 으로 노출한다. 소스/개발은 별도 소스 저장소에서 관리한다.

## 사용 (SPM)

Xcode 의 Package Dependencies 에 추가:

```
https://github.com/Geoplan-Mobile/gpi-prm
```

```swift
import gpi_prm

let mioc = MIocFactory.getInstance()
mioc.setCallback(callback: myCallback)            // MIocCallback 구현체
mioc.start(areaInfoList: [area], wallInfoList: [wall])
mioc.pushEvent(spaceId: 1, tagId: "TAG-001", x: 5, y: 5, z: 0)
mioc.stop()
```

공개 API: `MIoc`, `MIocFactory`, `MIocCallback`, `AreaInfo`, `WallInfo`.

## 구조 (wrapper 패턴)

- `gpi-prm.xcframework` — 컴파일된 바이너리 (ios-arm64 / ios-arm64_x86_64-simulator)
- `Package.swift` — `binaryTarget(gpi-prm)` + `deps carrier(gpi-prm-deps)` 를 한 library 로 묶음
  - carrier 가 `GEOSwift` 를 짊어져 소비측에 자동 전파 (binaryTarget 은 deps 를 직접 못 받음)

> 저장소가 Private 이면, 사용할 외부 개발자 GitHub 계정을 이 저장소의 **Collaborator** 로 추가해야 SPM 인증이 통과된다.

## 버전

현재: **1.0.0** (`gpi-prm.xcframework/VERSION_1.0.0` 마커로 확인 가능)
