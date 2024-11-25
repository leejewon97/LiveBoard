import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'https://REMOVED_HOST/graphql';
  static const String _apiKey = 'REMOVED_API_KEY';

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

  Future<Map<String, dynamic>> createChannel(String name) async {
    final result = await _query(
      'mutation CreateChannel(\$name: String!) { createChannel(name: \$name) { id name } }',
      variables: {'name': name},
    );
    return result['createChannel'];
  }

  // 메모 관련 메서드
  Future<List<dynamic>> getMemosByChannel(String channelId) async {
    final result = await _query(
      '''query GetMemosByChannel(\$channelId: ID!) {
        getMemosByChannel(channelId: \$channelId) {
          id message x_position y_position createdAt updatedAt
        }
      }''',
      variables: {'channelId': channelId},
    );
    return result['getMemosByChannel'];
  }
}
