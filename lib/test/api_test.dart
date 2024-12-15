import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiTest extends StatefulWidget {
  const ApiTest({super.key});

  @override
  State<ApiTest> createState() => _ApiTestState();
}

class _ApiTestState extends State<ApiTest> {
  final ApiService _apiService = ApiService();
  final _logs = <String>[];
  String? _selectedChannelId;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now()}: $message');
    });
  }

  // 채널 관련 테스트
  Future<void> _testGetChannels() async {
    try {
      final channels = await _apiService.getChannels();
      _addLog('채널 목록 조회 성공: ${channels.length}개');

      // 모든 채널의 정보를 로그에 추가
      for (var channel in channels) {
        _addLog('name: ${channel['name']} (ID: ${channel['id']})');
      }

      // 마지막 채널을 선택된 채널로 설정
      if (channels.isNotEmpty) {
        _selectedChannelId = channels[channels.length - 1]['id'];
        _addLog('마지막 채널 ID: $_selectedChannelId');
      }
    } catch (e) {
      _addLog('채널 목록 조회 실패: $e');
    }
  }

  Future<void> _testCreateChannel() async {
    try {
      final channel =
          await _apiService.createChannel('테스트 채널 ${DateTime.now()}');
      _addLog('채널 생성 성공: ${channel['name']}');
      _selectedChannelId = channel['id'];
    } catch (e) {
      _addLog('채널 생성 실패: $e');
    }
  }

  Future<void> _testGetChannel() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      final channel = await _apiService.getChannel(_selectedChannelId!);
      _addLog('채널 조회 성공: ${channel['name']}');
    } catch (e) {
      _addLog('채널 조회 실패: $e');
    }
  }

  Future<void> _testDeleteChannel() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      await _apiService.deleteChannel(_selectedChannelId!);
      _addLog('채널 삭제 성공');
      _selectedChannelId = null;
    } catch (e) {
      _addLog('채널 삭제 실패: $e');
    }
  }

  // 메모 관련 테스트
  Future<void> _testGetMemosByChannel() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      final memos = await _apiService.getMemosByChannel(_selectedChannelId!);
      _addLog('메모 목록 조회 성공: ${memos.length}개');
    } catch (e) {
      _addLog('메모 목록 조회 실패: $e');
    }
  }

  Future<void> _testCreateMemo() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      final memo = await _apiService.createMemo(
        channelId: _selectedChannelId!,
        message: '테스트 메모 ${DateTime.now()}',
        xPosition: 100,
        yPosition: 100,
      );
      _addLog('메모 생성 성공: ${memo['message']}');
    } catch (e) {
      _addLog('메모 생성 실패: $e');
    }
  }

  // 메모 수정 테스트
  Future<void> _testUpdateMemo() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      // 1. 먼저 해당 채널의 메모 목록을 가져옴
      final memos = await _apiService.getMemosByChannel(_selectedChannelId!);
      if (memos.isEmpty) {
        _addLog('수정할 메모가 없습니다');
        return;
      }

      // 2. 마지막 메모를 수정
      final memoToUpdate = memos[memos.length - 1];
      final updatedMemo = await _apiService.updateMemo(
        channelId: _selectedChannelId!,
        id: memoToUpdate['id'],
        message: '수정된 메모 ${DateTime.now()}',
        xPosition: 200,
        yPosition: 200,
      );
      _addLog('메모 수정 성공: ${updatedMemo['message']}');
    } catch (e) {
      _addLog('메모 수정 실패: $e');
    }
  }

  // 메모 삭제 테스트
  Future<void> _testDeleteMemo() async {
    if (_selectedChannelId == null) {
      _addLog('선택된 채널이 없습니다');
      return;
    }
    try {
      // 1. 먼저 해당 채널의 메모 목록을 가져옴
      final memos = await _apiService.getMemosByChannel(_selectedChannelId!);
      if (memos.isEmpty) {
        _addLog('삭제할 메모가 없습니다');
        return;
      }

      // 2. 마지막 메모를 삭제
      final memoToDelete = memos[memos.length - 1];
      await _apiService.deleteMemo(
        channelId: _selectedChannelId!,
        id: memoToDelete['id'],
      );
      _addLog('메모 삭제 성공');
    } catch (e) {
      _addLog('메모 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              // 채널 관련 버튼
              ElevatedButton(
                onPressed: _testGetChannels,
                child: const Text('채널 목록'),
              ),
              ElevatedButton(
                onPressed: _testCreateChannel,
                child: const Text('채널 생성'),
              ),
              ElevatedButton(
                onPressed: _testGetChannel,
                child: const Text('채널 조회'),
              ),
              ElevatedButton(
                onPressed: _testDeleteChannel,
                child: const Text('채널 삭제'),
              ),
              // 메모 관련 버튼
              ElevatedButton(
                onPressed: _testGetMemosByChannel,
                child: const Text('메모 목록'),
              ),
              ElevatedButton(
                onPressed: _testCreateMemo,
                child: const Text('메모 생성'),
              ),
              ElevatedButton(
                onPressed: _testUpdateMemo,
                child: const Text('메모 수정'),
              ),
              ElevatedButton(
                onPressed: _testDeleteMemo,
                child: const Text('메모 삭제'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(_logs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _logs.clear();
          });
        },
        child: const Icon(Icons.clear),
      ),
    );
  }
}
