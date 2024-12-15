import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Memo {
  final String id;
  final Offset position;
  String content;

  Memo({
    required this.id,
    required this.position,
    required this.content,
  });
}

class MemoRoomScreen extends StatefulWidget {
  final String roomId;

  const MemoRoomScreen({super.key, required this.roomId});

  @override
  State<MemoRoomScreen> createState() => _MemoRoomScreenState();
}

class _MemoRoomScreenState extends State<MemoRoomScreen> {
  final ApiService _apiService = ApiService();
  final Map<int, GlobalKey> _memoKeys = {};
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  List<Memo> memos = [];
  final _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    try {
      final memoList = await _apiService.getMemosByChannel(widget.roomId);
      setState(() {
        memos = memoList
            .map((memo) => Memo(
                  id: memo['id'],
                  position: Offset(
                    memo['x_position'].toDouble(),
                    memo['y_position'].toDouble(),
                  ),
                  content: memo['message'],
                ))
            .toList();
      });
    } catch (e) {
      // 에러 처리
    }
  }

  void _createMemo(TapDownDetails details) async {
    final RenderBox stackBox =
        _stackKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = stackBox.globalToLocal(details.globalPosition);

    try {
      final memo = await _apiService.createMemo(
        channelId: widget.roomId,
        message: '',
        xPosition: localPosition.dx.round(),
        yPosition: localPosition.dy.round(),
      );

      setState(() {
        memos.add(Memo(
          id: memo['id'],
          position: Offset(
            memo['x_position'].toDouble(),
            memo['y_position'].toDouble(),
          ),
          content: memo['message'],
        ));
      });

      final index = memos.length - 1;
      _focusNodes[index] ??= FocusNode();
      _focusNodes[index]?.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 생성에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteMemo(int index) async {
    try {
      final memo = memos[index];
      await _apiService.deleteMemo(
        channelId: widget.roomId,
        id: memo.id,
      );
      setState(() {
        memos.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 삭제에 실패했습니다: $e')),
        );
      }
    }
  }

  void _handleMemoChanged(int index) async {
    final memo = memos[index];
    final controller = _controllers[index];
    if (controller == null) return;

    try {
      await _apiService.updateMemo(
        channelId: widget.roomId,
        id: memo.id,
        message: controller.text,
        xPosition: memo.position.dx.round(),
        yPosition: memo.position.dy.round(),
      );
      setState(() {
        memo.content = controller.text;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 수정에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방 ${widget.roomId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        key: _stackKey,
        children: [
          // 배경과 새 메모 생성을 위한 GestureDetector
          GestureDetector(
            onTapDown: _createMemo,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // 기존 메모들
          ...memos.asMap().entries.map((entry) {
            final index = entry.key;
            final memo = entry.value;
            _memoKeys[index] ??= GlobalKey();

            return Positioned(
              left: memo.position.dx,
              top: memo.position.dy,
              child: Stack(
                key: _memoKeys[index],
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _controllers[index] ??=
                            TextEditingController(text: memo.content)
                              ..addListener(() => _handleMemoChanged(index)),
                        focusNode: _focusNodes[index] ??= FocusNode(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 16),
                        maxLines: null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _deleteMemo(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 24,
                        height: 24,
                        color: Colors.black12,
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _memoKeys.clear();
    super.dispose();
  }
}
