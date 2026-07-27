/// 운영 빌드 여부. 빌드 파이프라인이 `--dart-define=PROD=true`로 주입한다.
const bool kIsProd = bool.fromEnvironment('PROD');

/// 백엔드 API 베이스 URL. 프로젝트 환경별 값을 dart-define으로 주입한다.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example.com',
);
