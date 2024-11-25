import 'package:flutter/material.dart';
import 'memo_room_screen.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방 목록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: 5, // 임시 데이터
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('방 ${index + 1}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MemoRoomScreen(roomId: index.toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새로운 방 만들기 기능 구현 예정
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
