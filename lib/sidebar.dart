import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final List<String> conversations;
  final Function(int) onConversationSelected;
  final int selectedConversationIndex;

  Sidebar({
    required this.conversations,
    required this.onConversationSelected,
    required this.selectedConversationIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: Colors.grey[900],
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Center(
              child: Text(
                conversations[index],
                style: TextStyle(color: selectedConversationIndex == index ? Colors.white : Colors.grey[600]),
                textAlign: TextAlign.center, // Centering the text horizontally
              ),
            ),
            selected: selectedConversationIndex == index,
            onTap: () => onConversationSelected(index),
            tileColor: selectedConversationIndex == index ? const Color.fromARGB(255, 87, 87, 87) : Colors.grey[900],
          );
        },
      ),
    );
  }
}