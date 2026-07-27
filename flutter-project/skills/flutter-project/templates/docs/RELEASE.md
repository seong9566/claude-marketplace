# 릴리즈

## 현재 자동화 범위

`.github/workflows/release.yml`은 `v*` 태그가 push되면 태그에서 버전을 읽고
확인용 Android APK를 빌드해 GitHub Release에 첨부한다. Android 배포 서명,
iOS 서명, TestFlight·Firebase App Distribution·Play Console 업로드는 하지
않는다.

## Android 서명 연결

배포용 빌드에는 keystore를 base64로 인코딩해 GitHub Secrets에 저장하고,
워크플로에서 keystore 파일과 `key.properties`를 복원하는 단계를 추가한다.
필요한 시크릿 이름은 다음처럼 정할 수 있다.

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## iOS 서명 연결

App Store Connect API 키와 배포 인증서·프로비저닝 프로파일 관리가 필요하다.
인증서는 fastlane match 같은 도구로 관리할 수 있다. 시크릿 이름 예시는
다음과 같다.

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_CONTENT`

서명 구성을 마친 뒤 GitHub Actions 변수 `ENABLE_IOS_RELEASE`를 `true`로
설정해 `release.yml`의 iOS 잡을 활성화한다.

## 배포 채널 선택

TestFlight, Firebase App Distribution, Play Console 내부 테스트 중 프로젝트에
맞는 채널을 선택해 연결한다. 이 골격은 특정 채널을 기본값으로 정하지 않는다.

## 버저닝

단순한 방식은 version에 Git 태그를, build number에 CI 실행 번호를 쓰는 것이다.
스토어의 최신 build number를 조회해 1을 더할 수도 있지만 스토어 API 연동이
추가로 필요하다.
