import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class WebSocketService {
  static const String _host = 'REMOVED_HOST';
  static const String _wsUrl = 'wss://REMOVED_HOST/graphql/realtime';
  static const String _apiKey = 'REMOVED_API_KEY';
  IOWebSocketChannel? _channel;

  // 콜백 함수들
  Function(Map<String, dynamic>)? onMemoCreated;
  Function(Map<String, dynamic>)? onMemoUpdated;
  Function(Map<String, dynamic>)? onMemoDeleted;

  // Base64 인코딩 헬퍼 함수
  String _encodeCredentials() {
    final creds = {
      'host': _host,
      'x-api-key': _apiKey,
    };
    return base64.encode(utf8.encode(jsonEncode(creds)));
  }

  // WebSocket URL 생성
  String _getWebsocketUrl() {
    final header = _encodeCredentials();
    final payload = base64.encode(utf8.encode('{}'));
    return '$_wsUrl?header=$header&payload=$payload';
  }

  // WebSocket 연결
  void connect(String channelId) async {
    Logger().i('[LiveBoard] WebSocket 연결 시도...');

    try {
      final socket = await WebSocket.connect(
        _getWebsocketUrl(),
        protocols: ['graphql-ws'],
      );

      _channel = IOWebSocketChannel(socket);

      // connection_init 메시지 전송
      final initMessage = jsonEncode({
        'type': 'connection_init',
      });
      _channel?.sink.add(initMessage);

      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);

          if (data['type'] == 'connection_ack') {
            Logger().i('[LiveBoard] WebSocket 연결 성공');
            _subscribeToEvents(channelId);
          } else if (data['type'] == 'error') {
            Logger().e('[LiveBoard] WebSocket 에러: ${data['payload']}');
          } else if (data['type'] == 'data') {
            final payload = data['payload']['data'];
            if (payload['subscribeCreate'] != null) {
              onMemoCreated?.call(payload['subscribeCreate']);
            } else if (payload['subscribeUpdate'] != null) {
              onMemoUpdated?.call(payload['subscribeUpdate']);
            } else if (payload['subscribeDelete'] != null) {
              onMemoDeleted?.call(payload['subscribeDelete']);
            }
          }
        },
        onError: (error) =>
            Logger().e('[LiveBoard] WebSocket 에러', error: error),
        onDone: () {
          Logger().i('[LiveBoard] WebSocket 연결 종료');
          // 재연결 시도
          connect(channelId);
        },
      );

      Logger().i('[LiveBoard] WebSocket 초기화 완료');
    } catch (e) {
      Logger().e('[LiveBoard] WebSocket 연결 실패', error: e);
      Future.delayed(const Duration(seconds: 3), () => connect(channelId));
    }
  }

  // 이벤트 구독
  void _subscribeToEvents(String channelId) {
    Logger().i('[LiveBoard] 채널 $channelId에 대한 구독 시작');

    // 메모 생성 구독
    final createMessage = jsonEncode({
      'id': '${DateTime.now().millisecondsSinceEpoch}_create',
      'type': 'start',
      'payload': {
        'data': jsonEncode({
          'query': '''
            subscription MySubscription2 {
              subscribeCreate {
                channelId
                id
                message
                x_position
                y_position
                createdAt
                updatedAt
              }
            }
          '''
        }),
        'extensions': {
          'authorization': {
            'x-api-key': _apiKey,
            'host': _host,
          },
        },
      }
    });

    // 메모 수정 구독
    final updateMessage = jsonEncode({
      'id': '${DateTime.now().millisecondsSinceEpoch}_update',
      'type': 'start',
      'payload': {
        'data': jsonEncode({
          'query': '''
            subscription MySubscription2 {
              subscribeUpdate {
                channelId
                id
                message
                x_position
                y_position
                createdAt
                updatedAt
              }
            }
          '''
        }),
        'extensions': {
          'authorization': {
            'x-api-key': _apiKey,
            'host': _host,
          },
        },
      }
    });

    // 메모 삭제 구독
    final deleteMessage = jsonEncode({
      'id': '${DateTime.now().millisecondsSinceEpoch}_delete',
      'type': 'start',
      'payload': {
        'data': jsonEncode({
          'query': '''
            subscription MySubscription2 {
              subscribeDelete {
                channelId
                id
                message
                x_position
                y_position
                createdAt
                updatedAt
              }
            }
          '''
        }),
        'extensions': {
          'authorization': {
            'x-api-key': _apiKey,
            'host': _host,
          },
        },
      }
    });

    _channel?.sink.add(createMessage);
    _channel?.sink.add(updateMessage);
    _channel?.sink.add(deleteMessage);
  }

  // 연결 종료
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  // 자 해제
  void dispose() {
    disconnect();
  }
}
