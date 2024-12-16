import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/memo_box.dart';

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

  Future<void> _updateMemo({
    required String id,
    required String content,
    required Offset position,
    required int index,
  }) async {
    // 현재 메모 상태 저장
    final originalMemo = memos[index];

    // 즉시 UI 업데이트 (낙관적 업데이트)
    setState(() {
      memos[index] = Memo(
        id: id,
        position: position,
        content: content,
      );
    });

    try {
      await _apiService.updateMemo(
        channelId: widget.roomId,
        id: id,
        message: content,
        xPosition: position.dx.round(),
        yPosition: position.dy.round(),
      );
    } catch (e) {
      // 실패시 원래 상태로 복구
      if (mounted) {
        setState(() {
          memos[index] = originalMemo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메모 수정에 실패했습니다')),
        );
      }
    }
  }

  void _handleMemoChanged(int index) async {
    final memo = memos[index];
    final controller = _controllers[index];
    if (controller == null) return;

    await _updateMemo(
      id: memo.id,
      content: controller.text,
      position: memo.position,
      index: index,
    );
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
              child: Draggable(
                feedback: Material(
                  elevation: 4,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: MemoBox(
                    content: memo.content,
                  ),
                ),
                childWhenDragging: Container(),
                onDragEnd: (details) async {
                  final RenderBox stackBox =
                      _stackKey.currentContext!.findRenderObject() as RenderBox;
                  final localPosition = stackBox.globalToLocal(details.offset);

                  await _updateMemo(
                    id: memo.id,
                    content: memo.content,
                    position: localPosition,
                    index: index,
                  );
                },
                child: Stack(
                  key: _memoKeys[index],
                  clipBehavior: Clip.none,
                  children: [
                    MemoBox(
                      content: memo.content,
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
