import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/memo_box.dart';
import 'dart:async'; // Timer를 위해 추가

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
  final WebSocketService _webSocketService = WebSocketService();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  List<Memo> memos = [];
  final _stackKey = GlobalKey();
  Timer? _debounce; // 디바운스를 위한 Timer 추가

  @override
  void initState() {
    super.initState();
    _loadMemos();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    Logger().i('[LiveBoard] WebSocket 초기화 시작: 채널 ID ${widget.roomId}');

    _webSocketService.onMemoCreated = (memo) {
      Logger().i('[LiveBoard] WebSocket: 메모 생성 이벤트 수신', error: memo);
      _handleRemoteMemoCreated(memo);
    };

    _webSocketService.onMemoUpdated = (memo) {
      Logger().i('[LiveBoard] WebSocket: 메모 수정 이벤트 수신', error: memo);
      _handleRemoteMemoUpdated(memo);
    };

    _webSocketService.onMemoDeleted = (memo) {
      Logger().i('[LiveBoard] WebSocket: 메모 삭제 이벤트 수신', error: memo);
      _handleRemoteMemoDeleted(memo);
    };

    _webSocketService.connect(widget.roomId);
    Logger().i('[LiveBoard] WebSocket 연결 시도 완료');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모를 불러오는데 실패했습니다: $e')),
        );
      }
      Logger().e('[LiveBoard] 메모 로딩 실패', error: e);
    }
  }

  Future<void> _createMemo(TapDownDetails details) async {
    final RenderBox stackBox =
        _stackKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = stackBox.globalToLocal(details.globalPosition);

    final newIndex = memos.length;
    final focusNode = FocusNode();

    try {
      await _apiService.createMemo(
        channelId: widget.roomId,
        message: '',
        xPosition: localPosition.dx.round(),
        yPosition: localPosition.dy.round(),
      );

      _focusNodes[newIndex] = focusNode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[newIndex]?.requestFocus();
      });
    } catch (e) {
      focusNode.dispose();
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

      // 컨트롤러와 FocusNode 정리는 WebSocket 이벤트 수신 후에 하도록 변경
      await _apiService.deleteMemo(
        channelId: widget.roomId,
        id: memo.id,
      );
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

  void _handleMemoTextUpdated(int index) {
    // 이전 타이머가 있다면 취소
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final memo = memos[index];
    final controller = _controllers[index];
    if (controller == null || memo.content == controller.text) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _updateMemo(
        id: memo.id,
        content: controller.text,
        position: memo.position,
        index: index,
      );
    });
  }

  // 다른 사용자가 메모를 생성했을 때
  void _handleRemoteMemoCreated(Map<String, dynamic> memo) {
    if (memo['channelId'] != widget.roomId) return;

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
    Logger().i('[LiveBoard] 새 메모가 추가됨: ${memo['message']}');
  }

  // 다른 사용자가 메모를 수정했을 때
  void _handleRemoteMemoUpdated(Map<String, dynamic> memo) {
    if (memo['channelId'] != widget.roomId) return;

    final index = memos.indexWhere((m) => m.id == memo['id']);
    if (index == -1) return;

    setState(() {
      memos[index] = Memo(
        id: memo['id'],
        position: Offset(
          memo['x_position'].toDouble(),
          memo['y_position'].toDouble(),
        ),
        content: memo['message'],
      );
      _controllers[index]?.text = memo['message'];
    });
    Logger().i('[LiveBoard] 메모가 수정됨: ${memo['message']}');
  }

  // 다른 사용자가 메모를 삭제했을 때
  void _handleRemoteMemoDeleted(Map<String, dynamic> memo) {
    if (memo['channelId'] != widget.roomId) return;

    final index = memos.indexWhere((m) => m.id == memo['id']);
    if (index == -1) return;

    // 포커스 제거
    for (var focusNode in _focusNodes.values) {
      focusNode.unfocus();
    }

    // 컨트롤러와 FocusNode 정리
    _controllers[index]?.dispose();
    _focusNodes[index]?.dispose();
    _controllers.remove(index);
    _focusNodes.remove(index);

    setState(() {
      memos.removeAt(index);
    });

    // 삭제된 메모 이후의 컨트롤러와 FocusNode 인덱스 조정
    for (var i = index; i < memos.length; i++) {
      if (_controllers.containsKey(i + 1)) {
        final oldController = _controllers[i + 1]!;
        final text = oldController.text;
        oldController.dispose(); // 이전 컨트롤러 정리

        _controllers[i] = TextEditingController(text: text)
          ..addListener(() => _handleMemoTextUpdated(i));
        _controllers.remove(i + 1);
      }
      if (_focusNodes.containsKey(i + 1)) {
        _focusNodes[i] = _focusNodes[i + 1]!;
        _focusNodes.remove(i + 1);
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
      body: InteractiveViewer(
        minScale: 0.3,
        maxScale: 2.0,
        constrained: false,
        child: Container(
          width: 5000,
          height: 3000,
          margin: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.inversePrimary,
              width: 4.0,
            ),
          ),
          child: Stack(
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
                return Positioned(
                  left: memo.position.dx,
                  top: memo.position.dy,
                  child: Draggable(
                    onDragStarted: () {
                      for (var focusNode in _focusNodes.values) {
                        focusNode.unfocus();
                      }
                    },
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
                      final RenderBox stackBox = _stackKey.currentContext!
                          .findRenderObject() as RenderBox;
                      final localPosition =
                          stackBox.globalToLocal(details.offset);

                      await _updateMemo(
                        id: memo.id,
                        content: memo.content,
                        position: localPosition,
                        index: index,
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MemoBox(
                          content: memo.content,
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _controllers[index] ??=
                                  TextEditingController(text: memo.content)
                                    ..addListener(
                                        () => _handleMemoTextUpdated(index)),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel(); // 타이머 정리
    _webSocketService.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    super.dispose();
  }
}
