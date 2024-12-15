import 'package:flutter/material.dart';

class Memo {
  final Offset position;
  String content;

  Memo({required this.position, required this.content});
}

class MemoRoomScreen extends StatefulWidget {
  final String roomId;

  const MemoRoomScreen({super.key, required this.roomId});

  @override
  State<MemoRoomScreen> createState() => _MemoRoomScreenState();
}

class _MemoRoomScreenState extends State<MemoRoomScreen> {
  final Map<int, GlobalKey> _memoKeys = {};
  final List<Memo> memos = [];

  void _handleTapDown(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // 탭한 위치에 이미 메모가 있는지 확인
    final existingMemoIndex = _findMemoAtPosition(localPosition);

    if (existingMemoIndex == -1) {
      // 새 메모 생성
      setState(() {
        memos.add(Memo(position: localPosition, content: ''));
      });
      _showEditDialog(memos.length - 1);
    } else {
      // 기존 메모 수정
      _showEditDialog(existingMemoIndex);
    }
  }

  int _findMemoAtPosition(Offset tapPosition) {
    for (int i = 0; i < memos.length; i++) {
      final key = _memoKeys[i];
      if (key?.currentContext == null) continue;

      final RenderBox renderBox =
          key!.currentContext!.findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      final Offset memoPosition = renderBox.localToGlobal(Offset.zero);

      final memoRect = Rect.fromLTWH(
        memoPosition.dx,
        memoPosition.dy,
        size.width,
        size.height,
      );

      if (memoRect.contains(tapPosition)) {
        return i;
      }
    }
    return -1;
  }

  void _showEditDialog(int memoIndex) {
    final controller = TextEditingController(text: memos[memoIndex].content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 편집'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '메모 내용을 입력하세요'),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (controller.text.isEmpty) {
                  memos.removeAt(memoIndex);
                } else {
                  memos[memoIndex].content = controller.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _deleteMemo(int index) {
    setState(() {
      memos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방 ${widget.roomId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          // 배경과 새 메모 생성을 위한 GestureDetector
          GestureDetector(
            onTapDown: _handleTapDown,
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
                  GestureDetector(
                    onTapDown: _handleTapDown,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      constraints: const BoxConstraints(
                        maxWidth: 200, // 최대 너비 제한
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
                        child: Text(
                          memo.content,
                          style: const TextStyle(fontSize: 16),
                          softWrap: true,
                        ),
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
    _memoKeys.clear();
    super.dispose();
  }
}
