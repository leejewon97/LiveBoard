import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'memo_room_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      setState(() => _isLoading = true);
      final channels = await _apiService.getChannels();
      setState(() {
        _channels = channels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채널 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _createChannel() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _CreateChannelDialog(),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await _apiService.createChannel(name);
        _loadChannels(); // 목록 새로고침
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('채널 생성에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteChannel(String channelId, String channelName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채널 삭제'),
        content: Text('정말 [$channelName] 채널을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteChannel(channelId);
        _loadChannels(); // 목록 새로고침
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('채널 삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채널 목록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChannels,
              child: _channels.isEmpty
                  ? const Center(child: Text('채널이 없습니다'))
                  : ListView.builder(
                      itemCount: _channels.length,
                      itemBuilder: (context, index) {
                        final channel = _channels[index];
                        return ListTile(
                          title: Text(channel['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _deleteChannel(
                              channel['id'],
                              channel['name'],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MemoRoomScreen(roomId: channel['id']),
                              ),
                            ).then((_) => _loadChannels());
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChannel,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CreateChannelDialog extends StatelessWidget {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 채널 만들기'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: '채널 이름을 입력하세요'),
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('만들기'),
        ),
      ],
    );
  }
}
