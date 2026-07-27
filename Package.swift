// swift-tools-version: 5.9
//
// gpi-prm 배포(Release) 매니페스트 — wrapper 패턴 (binaryTarget + deps carrier).
//
// 소비 앱은 이 저장소를 SPM 으로 의존한다:
//   https://github.com/Geoplan-Mobile/gpi-prm  (from: "1.0.0")
//   import gpi_prm
//
// carrier(gpi-prm-deps) 가 geos · gpi-logger 를 짊어져, 소비측이 이를 직접 선언하지
// 않아도 자동 전파된다. (binaryTarget 은 SPM 제약상 dependencies 를 못 받음)
//
// ⚠️ GEOSwift(Swift 래퍼)는 xcframework 에 정적으로 흡수돼 있고 public API 에도
//    노출되지 않으므로 전파하지 않는다. (전파하면 소비측이 GEOSwift 를 재컴파일해
//    바이너리 내 정적본과 중복 → 심볼 충돌.) 런타임에 동적 링크되는 geos(C 라이브러리)
//    만 carrier 로 제공한다.
//
// 새 버전 배포: gpi-prm 소스 repo 에서 build_xcframework.sh 로 xcframework 갱신 →
// 이 저장소의 gpi-prm.xcframework 교체(폴더 완전 삭제 후 주입) → commit + tag x.y.z + push.
//
import PackageDescription

let package = Package(
    name: "gpi-prm",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // binaryTarget 과 deps carrier 를 한 library 로 묶음 — 소비측이 한 번 의존하면
        // 바이너리 + geos + gpi-logger 가 함께 build graph 에 들어온다.
        .library(name: "gpi-prm", targets: ["gpi-prm", "gpi-prm-deps"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GEOSwift/geos.git", from: "9.0.0"),
        .package(url: "https://github.com/Geoplan-Mobile/gpi-logger", from: "1.0.1"),
    ],
    targets: [
        // 실제 라이브러리 — 사용자가 import 하는 대상.
        .binaryTarget(
            name: "gpi-prm",
            path: "gpi-prm.xcframework"
        ),
        // deps carrier — binaryTarget 이 dependencies 를 직접 못 받는 SPM 제약 우회.
        .target(
            name: "gpi-prm-deps",
            dependencies: [
                .product(name: "geos", package: "geos"),
                .product(name: "gpi-logger", package: "gpi-logger"),
            ],
            path: "Sources/gpi-prm-deps"
        ),
    ]
)
