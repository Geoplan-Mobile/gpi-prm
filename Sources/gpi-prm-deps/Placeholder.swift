// gpi-prm-deps: 빈 carrier 타깃.
//
// binaryTarget(gpi-prm.xcframework) 는 SPM 제약상 dependencies 를 직접 선언하지 못한다.
// 그래서 외부 의존성(GEOSwift)을 이 빈 타깃이 대신 짊어지고, library product 로 함께
// 묶여 소비측에 전파한다. 의도적으로 코드가 없다 (선언 전달 전용).
