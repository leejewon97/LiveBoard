import 'package:flutter/material.dart';

class MemoRoomScreen extends StatefulWidget {
  final String roomId;

  const MemoRoomScreen({super.key, required this.roomId});

  @override
  State<MemoRoomScreen> createState() => _MemoRoomScreenState();
}

class _MemoRoomScreenState extends State<MemoRoomScreen> {
  final List<String> memos = []; // 임시 메모 저장소

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방 ${widget.roomId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: memos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(memos[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새로운 메모 추가 기능 구현 예정
        },
        child: const Icon(Icons.note_add),
      ),
    );
  }
}
