import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env.dart';

class ApiService {
  static const String _baseUrl = Env.apiUrl;
  static const String _apiKey = Env.apiKey;

  Future<dynamic> _query(String query,
      {Map<String, dynamic>? variables}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode({
          'query': query,
          if (variables != null) 'variables': variables,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'][0]['message']);
        }
        return data['data'];
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API 요청 중 오류 발생: $e');
    }
  }

  // 채널 관련 메서드
  Future<List<dynamic>> getChannels() async {
    final result = await _query('{ listChannels { id name } }');
    return result['listChannels'];
  }

  Future<Map<String, dynamic>> getChannel(String id) async {
    final result = await _query(
      'query GetChannel(\$id: ID!) { getChannel(id: \$id) { id name } }',
      variables: {'id': id},
    );
    return result['getChannel'];
  }

  Future<Map<String, dynamic>> createChannel(String name) async {
    final result = await _query(
      'mutation CreateChannel(\$name: String!) { createChannel(name: \$name) { id name } }',
      variables: {'name': name},
    );
    return result['createChannel'];
  }

  Future<Map<String, dynamic>> deleteChannel(String id) async {
    final result = await _query(
      'mutation DeleteChannel(\$id: ID!) { deleteChannel(id: \$id) { id } }',
      variables: {'id': id},
    );
    return result['deleteChannel'];
  }

  // 메모 관련 메서드
  Future<List<dynamic>> getMemosByChannel(String channelId) async {
    final result = await _query(
      '''query GetMemosByChannel(\$channelId: ID!) {
        getMemosByChannel(channelId: \$channelId) {
          channelId id message x_position y_position createdAt updatedAt
        }
      }''',
      variables: {'channelId': channelId},
    );
    return result['getMemosByChannel'];
  }

  Future<Map<String, dynamic>> createMemo({
    required String channelId,
    required String message,
    required int xPosition,
    required int yPosition,
  }) async {
    final result = await _query(
      '''mutation CreateMemo(
        \$channelId: ID!,
        \$message: String!,
        \$x_position: Int!,
        \$y_position: Int!
      ) {
        createMemo(
          channelId: \$channelId,
          message: \$message,
          x_position: \$x_position,
          y_position: \$y_position
        ) {
          channelId id message x_position y_position createdAt updatedAt
        }
      }''',
      variables: {
        'channelId': channelId,
        'message': message,
        'x_position': xPosition,
        'y_position': yPosition,
      },
    );
    return result['createMemo'];
  }

  Future<Map<String, dynamic>> updateMemo({
    required String channelId,
    required String id,
    required String message,
    required int xPosition,
    required int yPosition,
  }) async {
    final result = await _query(
      '''mutation UpdateMemo(
        \$channelId: ID!,
        \$id: ID!,
        \$message: String!,
        \$x_position: Int!,
        \$y_position: Int!
      ) {
        updateMemo(
          channelId: \$channelId,
          id: \$id,
          message: \$message,
          x_position: \$x_position,
          y_position: \$y_position
        ) {
          channelId id message x_position y_position createdAt updatedAt
        }
      }''',
      variables: {
        'channelId': channelId,
        'id': id,
        'message': message,
        'x_position': xPosition,
        'y_position': yPosition,
      },
    );
    return result['updateMemo'];
  }

  Future<Map<String, dynamic>> deleteMemo({
    required String channelId,
    required String id,
  }) async {
    final result = await _query(
      '''mutation DeleteMemo(\$channelId: ID!, \$id: ID!) {
        deleteMemo(channelId: \$channelId, id: \$id) {
          channelId id message x_position y_position createdAt updatedAt
        }
      }''',
      variables: {
        'channelId': channelId,
        'id': id,
      },
    );
    return result['deleteMemo'];
  }
}
