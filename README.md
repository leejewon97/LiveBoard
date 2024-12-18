# LiveBoard

실시간 협업 메모 보드 애플리케이션입니다. 여러 사용자가 동시에 접속하여 메모를 생성, 수정, 삭제할 수 있으며 모든 변경사항이 실시간으로 동기화됩니다.

## 주요 기능

- **실시간 협업**: WebSocket을 통한 실시간 메모 동기화
- **채널 관리**: 다중 채널(방) 생성 및 관리
- **메모 기능**:
  - 메모 생성/수정/삭제
  - 드래그 앤 드롭으로 메모 위치 이동
  - 자동 저장
- **사용자 인터페이스**:
  - 직관적인 메모 작성 및 편집
  - 확대/축소 가능한 무한 캔버스
  - 반응형 레이아웃

## 기술 스택

- **Frontend**: Flutter
- **상태 관리**: StatefulWidget
- **통신**:
  - GraphQL API (HTTP)
  - WebSocket (실시간 동기화)
- **기타**:
  - 디바운싱을 통한 성능 최적화
  - 낙관적 업데이트로 빠른 UI 응답성

## 시작하기

### 환경 설정

`lib/config/env.dart` 파일에서 다음 값들을 설정합니다:
- `apiHost`: API 서버 호스트 주소
- `apiUrl`: GraphQL API 엔드포인트 URL
- `wsUrl`: WebSocket 서버 URL
- `apiKey`: API 인증 키

예시:
```dart
class Env {
  static const String apiHost = 'your-api-host';
  static const String apiUrl = 'https://your-api-url';
  static const String wsUrl = 'wss://your-websocket-url';
  static const String apiKey = 'your-api-key';
}
```

### 주의사항
- `env.dart` 파일은 민감한 정보를 포함하고 있으므로 절대 Git에 커밋하지 마세요
- 이 파일은 `.gitignore`에 등록되어 있습니다

## 프로젝트 구조

```
lib/
├── config/         # 환경 설정
├── screens/        # 화면 UI
├── services/       # API 및 WebSocket 서비스
├── test/          # 테스트 코드
└── widgets/        # 재사용 가능한 위젯
```
